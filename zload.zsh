# Zsh Plugin Manager - zload.zsh
ZLOAD_HOME="${ZLOAD_HOME:-$HOME/.zload}"
ZLOAD_PLUGINS_DIR="${ZLOAD_PLUGINS_DIR:-${ZLOAD_DIR}/plugins}"
ZLOAD_SNIPPETS_DIR="${ZLOAD_SNIPPETS_DIR:-${ZLOAD_DIR}/snippets}"
DEFAULT_BRANCHES=("master" "main")

# Regular arrays to store parsed plugin data
ZPLUGINS_CLONE=()
ZPLUGINS_DOWNLOAD=()
ZPLUGINS_SOURCE=()
#ZPLUGINS_FPATH=()

# Function to download a .zsh file from a repository
download_file() {
    local repo=$1 filepath=$2
    local target_file="$ZLOAD_SNIPPETS_DIR/$repo/$filepath"
    mkdir -p $(dirname "$target_file")
    
    local raw_url="https://raw.githubusercontent.com/${repo}"
    for branch in "${DEFAULT_BRANCHES[@]}"; do
        local url="${raw_url}/${branch}/${filepath}"
        echo "Attempting to download $repo/$filepath from URL: $url"

        if command -v curl >/dev/null 2>&1; then
            if curl -fsSL "$url" -o "$target_file"; then
                echo "Successfully downloaded: $target_file"
                my_zcompile "$target_file"
                return 0
            fi
        elif command -v wget >/dev/null 2>&1; then
            if wget -q "$url" -O "$target_file"; then
                echo "Successfully downloaded: $target_file"
                my_zcompile "$target_file"
                return 0
            fi
        fi
    done
    echo "Error: Failed to download $filepath!"
    return 1
}

# Function to compile Zsh files into .zwc files
my_zcompile() {
    while (( $# )); do
        # Only zcompile if there isn't already a .zwc file or the .zwc is outdated,
        # and never compile zsh-syntax-highlighting's test data
        if [[ -s $1 && $1 != *.zwc &&
              ( ! -s ${1}.zwc || $1 -nt ${1}.zwc ) &&
              $1 != */test-data/* &&
              $1 != */test/* ]]; then
            builtin zcompile -UR "$1"
        fi
        shift
    done
}

handle_single_file() {
    local file=$1    
    first_slash=${file[(i)/]}
    second_slash=${file[(ib:first_slash+1:)/]}
    local repo=${file[1,second_slash-1]}
    local file_path=${file[second_slash+1,-1]}
    
    script_path="$ZLOAD_SNIPPETS_DIR/$file"
    if [[ ! -f $script_path ]]; then
        ZPLUGINS_DOWNLOAD+=("$repo" "$file_path")
    fi
    ZPLUGINS_SOURCE+=("$script_path")
    #ZPLUGINS_FPATH+=($(dirname "$script_path"))
}

handle_repo() {
    local repo=$1
    plugin_dir="${ZLOAD_PLUGINS_DIR}/$repo"
    prefix="$plugin_dir/${repo##*/}"
    zsh_file1="$prefix.plugin.zsh"
    zsh_file2="$prefix.zsh"
    if [[ ! -d $plugin_dir ]]; then
        ZPLUGINS_CLONE+=("$repo")
        ZPLUGINS_SOURCE+=("$zsh_file1")
        ZPLUGINS_SOURCE+=("$zsh_file2")
    else
        if [[ -f $zsh_file1 ]]; then
            ZPLUGINS_SOURCE+=("$zsh_file1")
        elif [[ -f $zsh_file2 ]]; then
            ZPLUGINS_SOURCE+=("$zsh_file2")
        fi
    fi
    #ZPLUGINS_FPATH+=("$plugin_dir")
}

handle_repo_and_files() {
    local args=("$@")
    local repo=${args[1]}
    plugin_dir="${ZLOAD_PLUGINS_DIR}/$repo"
    if [[ ! -d $plugin_dir ]]; then
        ZPLUGINS_CLONE+=("$repo")
    fi
    
    #ZPLUGINS_FPATH+=("$plugin_dir")
    for i in {2..${#args[@]}}; do
        ZPLUGINS_SOURCE+=("$plugin_dir/${args[i]}")
    done
}

handleL_repo_and_subdir_and_files() {
    local args=("$@")
    local repo=${args[1]}
    local subdir=${args[2]}
    
    plugin_dir="${ZLOAD_PLUGINS_DIR}/$repo/$subdir"
    if [[ ! -d $plugin_dir ]]; then
        ZPLUGINS_CLONE+=("$repo")
    fi
    
    #ZPLUGINS_FPATH+=("$plugin_dir")
    for i in {3..${#args[@]}}; do
        ZPLUGINS_SOURCE+=("$plugin_dir/${args[i]}")
    done
}

parse() {
    # Loop through each plugin's defs
    for i in {1..${#PLUGINS[@]}}; do
        defs=(${(z)PLUGINS[$i]})
        defs_count=${#defs[@]}
                
        if (( defs_count == 1 )); then
            if [[ ${defs[1]} == *.zsh ]]; then
                handle_single_file ${defs[@]}
            else
                handle_repo ${defs[@]}
            fi
        else
            if [[ ${defs[2]} == *.zsh ]]; then
                handle_repo_and_files ${defs[@]}
            else
                handleL_repo_and_subdir_and_files ${defs[@]}
            fi
        fi
    done
}

load() {
    local repo file plugin_dir
    local clone_happen

    # Clone plugins in parallel
    for repo in "${ZPLUGINS_CLONE[@]}"; do
        plugin_dir="${ZLOAD_PLUGINS_DIR}/${repo}"
        if [[ ! -d "$plugin_dir" ]]; then
            echo "Cloning $repo..."
            clone_happen="true"
            git clone --depth=1 "https://github.com/${repo}.git" "$plugin_dir" &
        fi
    done
    wait

    # Compile all Zsh files in cloned plugins (only after cloning)
    if [[ -n $clone_happen ]]; then
        echo compile cloned files
        for repo in "${ZPLUGINS_CLONE[@]}"; do
            plugin_dir="${ZLOAD_PLUGINS_DIR}/${repo}"
            if [[ -d "$plugin_dir" ]]; then
                for file in "$plugin_dir"/**/*.zsh(|-theme)(N.) "$plugin_dir"/**/prompt_*_setup(N.); do
                    my_zcompile "$file"
                done
            fi
        done
    fi

    # Download files in parallel
    for ((i = 1; i < ${#ZPLUGINS_DOWNLOAD[@]}; i += 2)); do
        repo="${ZPLUGINS_DOWNLOAD[i]}"
        file="${ZPLUGINS_DOWNLOAD[i+1]}"
        download_file "$repo" "$file" &
    done
    wait

    # Add unique paths to fpath
    #typeset -A unique_paths
    #for fp in "${ZPLUGINS_FPATH[@]}"; do
    #    unique_paths[$fp]=1
    #done
    #fpath+=(${(k)unique_paths})
    
    autoload -Uz compinit
    comp_dumpfile="${HOME}/.zcompdump_${EUID}_${OSTYPE}_${ZSH_VERSION}"
    compinit -d "$comp_dumpfile"
    
    # Source files
    for file in "${ZPLUGINS_SOURCE[@]}"; do
        source "$file"
    done
    
    # Compile the script and .zcompdump only if they have changed
    my_zcompile $0
    my_zcompile "$comp_dumpfile"
}

main() {
    parse
    load
}

main
