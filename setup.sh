#!/bin/bash
set -e

# Function to print messages
print_message() {
    echo "[INFO] $1"
}

print_warning() {
    echo "[WARNING] $1"
}

print_error() {
    echo "[ERROR] $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Go version
check_go_version() {
    if command_exists go; then
        GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        REQUIRED_VERSION="1.23"
        if [[ "$(printf '%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V | head -n1)" == "$REQUIRED_VERSION" ]]; then
            return 0
        fi
    fi
    return 1
}

# Detect OS
OS="$(uname -s)"
ARCH="$(uname -m)"

print_message "Detected OS: $OS, Architecture: $ARCH"

# Install Homebrew if on macOS and not installed
if [[ "$OS" == "Darwin" ]]; then
    if ! command_exists brew; then
        print_message "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for this session
        if [[ "$ARCH" == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        print_message "Homebrew is already installed"
    fi
fi

# Install Go if not installed or version is too old
if ! check_go_version; then
    print_message "Installing Go 1.23..."
    
    if [[ "$OS" == "Darwin" ]]; then
        brew install go@1.23
        brew link go@1.23 --force
    elif [[ "$OS" == "Linux" ]]; then
        GO_VERSION="1.23.4"
        if [[ "$ARCH" == "x86_64" ]]; then
            GO_ARCH="amd64"
        elif [[ "$ARCH" == "aarch64" ]]; then
            GO_ARCH="arm64"
        else
            GO_ARCH="$ARCH"
        fi
        
        print_message "Downloading Go ${GO_VERSION} for Linux ${GO_ARCH}..."
        wget -q "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
        rm "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
        
        # Add to PATH if not already there
        if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        fi
        if ! grep -q "/usr/local/go/bin" ~/.zshrc 2>/dev/null; then
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc 2>/dev/null || true
        fi
        export PATH=$PATH:/usr/local/go/bin
    fi
    
    print_message "Go installed: $(go version)"
else
    print_message "Go is already installed: $(go version)"
fi

# Install Podman if not installed
if ! command_exists podman; then
    print_message "Installing Podman..."
    
    if [[ "$OS" == "Darwin" ]]; then
        brew install podman
        
        # Initialize and start podman machine on macOS
        print_message "Initializing Podman machine..."
        podman machine init --cpus=2 --memory=4096 --disk-size=20
        podman machine start
    elif [[ "$OS" == "Linux" ]]; then
        # For Ubuntu/Debian based systems
        if command_exists apt-get; then
            print_message "Detected Ubuntu/Debian system. Installing Podman..."
            
            # Check Ubuntu version for proper repository
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                VERSION_ID=${VERSION_ID}
            fi
            
            sudo apt-get update
            
            # For Ubuntu 20.04 and later
            if [[ "${VERSION_ID}" == "20.04" ]] || [[ "${VERSION_ID}" == "22.04" ]] || [[ "${VERSION_ID}" == "24.04" ]]; then
                sudo apt-get install -y podman
            else
                # For older versions or other Debian-based systems
                sudo apt-get install -y podman || {
                    print_warning "Standard podman installation failed. Trying alternative method..."
                    # Add Kubic repository for podman
                    echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
                    curl -L "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/Release.key" | sudo apt-key add -
                    sudo apt-get update
                    sudo apt-get install -y podman
                }
            fi
        # For RHEL/CentOS/Fedora based systems
        elif command_exists yum; then
            sudo yum install -y podman
        elif command_exists dnf; then
            sudo dnf install -y podman
        else
            print_error "Unable to install Podman. Please install it manually."
            exit 1
        fi
    fi
    
    print_message "Podman installed: $(podman --version)"
else
    print_message "Podman is already installed: $(podman --version)"
    
    # Check if podman machine is running on macOS
    if [[ "$OS" == "Darwin" ]]; then
        if ! podman machine list | grep -q "Currently running"; then
            print_message "Starting Podman machine..."
            podman machine start
        fi
    fi
fi

# Install kubectl if not installed
if ! command_exists kubectl; then
    print_message "Installing kubectl..."
    
    if [[ "$OS" == "Darwin" ]]; then
        brew install kubectl
    elif [[ "$OS" == "Linux" ]]; then
        if [[ "$ARCH" == "x86_64" ]]; then
            KUBECTL_ARCH="amd64"
        elif [[ "$ARCH" == "aarch64" ]]; then
            KUBECTL_ARCH="arm64"
        else
            KUBECTL_ARCH="$ARCH"
        fi
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${KUBECTL_ARCH}/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    fi
    
    print_message "kubectl installed: $(kubectl version --client --short 2>/dev/null)"
else
    print_message "kubectl is already installed: $(kubectl version --client --short 2>/dev/null)"
fi

# Install minikube if not installed
if ! command_exists minikube; then
    print_message "Installing minikube..."
    
    if [[ "$OS" == "Darwin" ]]; then
        brew install minikube
    elif [[ "$OS" == "Linux" ]]; then
        if [[ "$ARCH" == "x86_64" ]]; then
            MINIKUBE_ARCH="amd64"
        elif [[ "$ARCH" == "aarch64" ]]; then
            MINIKUBE_ARCH="arm64"
        else
            MINIKUBE_ARCH="$ARCH"
        fi
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-${MINIKUBE_ARCH}
        sudo install minikube-linux-${MINIKUBE_ARCH} /usr/local/bin/minikube
        rm minikube-linux-${MINIKUBE_ARCH}
    fi
    
    print_message "minikube installed: $(minikube version --short)"
else
    print_message "minikube is already installed: $(minikube version --short)"
fi

print_message "All dependencies installed successfully!"
print_message ""
print_message "Setting up Kubernetes cluster and deploying application..."
print_message ""

# Check if minikube cluster exists and delete it if it does
if minikube status >/dev/null 2>&1; then
    read -p "A minikube cluster already exists and will be deleted. Do you want to continue? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_message "Using existing minikube cluster."
    else
        print_warning "Existing minikube cluster detected. Deleting..."
        minikube delete
        
        print_message "Starting minikube cluster with 3 nodes and Calico CNI..."
        minikube start --driver=podman --nodes=3 --cni=calico
        print_message "Waiting for cluster to be ready..."
        sleep 30
    fi
fi

print_message "Building container image..."
make image

# fix to load image at all nodes
print_message "Loading image to minikube..."
sed -i '' 's#k8s-issue-74839:latest#localhost/k8s-issue-74839:latest#g' deploy.yaml
sleep 1
podman save localhost/k8s-issue-74839:latest | minikube image load -
# Revert the change in deploy.yaml
sed -i '' 's#localhost/k8s-issue-74839:latest#k8s-issue-74839:latest#g' deploy.yaml
sleep 10

print_message "Deploying to Kubernetes..."
make deploy

sleep 20

print_message "Following pod logs..."
kubectl logs startup-script -f
