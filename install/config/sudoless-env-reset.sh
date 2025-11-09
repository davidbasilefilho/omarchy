#!/bin/sh
# Setup sudoers config to enable env_reset and pwfeedback
echo "Defaults env_reset,pwfeedback" | sudo tee /etc/sudoers.d/env-reset
sudo chmod 440 /etc/sudoers.d/env-reset

