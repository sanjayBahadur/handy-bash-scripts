#!/usr/bin/env bash
# Arch Linux Post-Install Setup Script
set -euo pipefail

# Logging setup
LOGFILE="/var/log/arch-postinstall.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "=== Arch Linux Post-Installation Script (GNOME + AI Dev) ==="

# 1. Ensure running as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Aborting."
    exit 1
    fi

    # 2. Detect first non-root user
    first_user=""
    first_user=$(awk -F: '$3>=1000 && $3<65000 {print $1; exit}' /etc/passwd || true)
    if [[ -z "$first_user" ]]; then
      echo "No regular user found. Let's create a new user."
        read -rp "Enter username for new user: " newuser
          # Create user with home directory and default groups (wheel for sudo)
            useradd -m -G wheel "$newuser"
              passwd "$newuser"
                first_user="$newuser"
                  echo "Created user '$first_user' and added to group wheel."
                  fi
                  echo "Using primary user: $first_user"

                  # 3. Sudo configuration: ensure wheel group has sudo enabled
                  # (Uncomment wheel group line in sudoers if not already)
                  if ! sudo -l -U "$first_user" &>/dev/null; then
                    echo "%wheel ALL=(ALL:ALL) ALL" | (EDITOR="tee -a" visudo --quiet --stdin)
                      echo "Enabled wheel group for sudo access43."
                      fi

                      # 4. Update system and install base packages
                      echo "Updating system and installing base packages..."
                      pacman -Syu --noconfirm
                      pacman -S --noconfirm --needed base-devel git sudo networkmanager docker

                      # 5. Enable NetworkManager and Docker services
                      echo "Enabling NetworkManager and Docker services..."
                      systemctl enable --now NetworkManager.service  # Start network manager44
                      systemctl enable --now docker.service          # Start Docker daemon45

                      # Add user to docker group for non-root docker usage
                      usermod -aG docker "$first_user" || true      # Add docker group46

                      # 6. Install Xorg, GNOME, GDM, and related components
                      echo "Installing GNOME desktop environment and GDM..."
                      pacman -S --noconfirm --needed xorg gnome gnome-extra gdm47
                      # In case gnome-extra was skipped, ensure gnome-tweaks is present
                      pacman -S --noconfirm --needed gnome-tweaks gnome-shell-extensions48

                      # 7. Enable GDM (display manager for GNOME)
                      systemctl enable gdm.service49
                      # Note: We don't start it immediately with --now, to avoid disrupting a running script in TTY.
                      echo "GDM enabled to start at boot50."

                      # 8. Development tools and web browsers
                      echo "Installing development tools and web browsers..."
                      pacman -S --noconfirm --needed firefox git zsh bat fd ripgrep neofetch btop kitty alacritty

                      # Use an AUR helper to install AUR packages: VS Code, Chrome, LibreWolf
                      # Install yay (AUR helper) if not installed
                      if ! command -v yay &>/dev/null; then
                        echo "Installing 'yay' AUR helper..."
                          sudo -u "$first_user" git clone https://aur.archlinux.org/yay.git /tmp/yay
                            pushd /tmp/yay
                              sudo -u "$first_user" makepkg -si --noconfirm
                                popd
                                fi

                                echo "Installing AUR packages: Visual Studio Code, Google Chrome, LibreWolf..."
                                sudo -u "$first_user" yay -S --noconfirm visual-studio-code-bin google-chrome librewolf-bin5152

                                # 9. Python and AI development libraries
                                echo "Installing Python AI development libraries..."
                                pacman -S --noconfirm --needed python python-pip jupyterlab53 \
                                  python-numpy python-scipy python-matplotlib python-pandas python-scikit-learn python-pytorch python-openai54

                                  # Use pip for HuggingFace Transformers (not in official repos)
                                  sudo -u "$first_user" pip install --no-cache-dir transformers

                                  # (Optional) Install other useful pip packages, e.g. for NLP, CV, etc.
                                  # sudo -u "$first_user" pip install --no-cache-dir nltk opencv-python

                                  # 10. Fonts and appearance
                                  echo "Installing fonts and appearance tweaks..."
                                  pacman -S --noconfirm --needed ttf-jetbrains-mono-nerd ttf-firacode-nerd55 papirus-icon-theme

                                  # Enable Shell extension support and User Themes extension
                                  sudo -u "$first_user" /bin/bash -c 'gsettings set org.gnome.shell disable-user-extensions false' || true56
                                  # The above might need the user to have logged in once; if it fails, it's non-critical.
                                  # Enable User Themes extension (so GNOME Tweaks can switch shell themes)
                                  sudo -u "$first_user" /bin/bash -c 'gsettings set org.gnome.shell.extensions.user-theme name "Adwaita-dark"' || true
                                  # (If Adwaita-dark is available, set it as an example; otherwise this is optional)

                                  # 11. Shell setup: change default shell to zsh for the user
                                  chsh -s /usr/bin/zsh "$first_user" || true
                                  echo "Default shell for $first_user set to Zsh."

                                  # Add neofetch to Zsh startup
                                  sudo -u "$first_user" bash -c 'echo -e "\n# Run neofetch on terminal launch\nif [[ -n \$PS1 ]]; then neofetch; fi" >> ~/.zshrc'
                                  # PS1 check ensures it's an interactive shell.

                                  # 12. Cleanup (if any)
                                  # Remove cached package builds to free space
                                  yes | pacman -Scc >/dev/null 2>&1 || true

                                  echo "=== Setup complete! ==="
                                  echo "User $first_user may need to re-login or reboot for some changes (groups, GDM) to take effect."
                                  echo "You can now reboot into GNOME (graphical login)57. Enjoy your new system!"