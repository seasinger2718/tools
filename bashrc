# System-wide .bashrc file for interactive bash(1) shells.
if [ -n "$PS1" ]; then PS1='\h:\w \u\$ '; fi
# Make bash check it's window size after a process completes
shopt -s checkwinsize

PATH=$PATH:/usr/local/bin:/usr/local/bin:/Users/tracy/Everything/Resources/Scripts
alias gopg="cd /Users/tracy/Everything/Activities/DDN_DVT/db/postgres"
