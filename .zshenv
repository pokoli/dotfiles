# User settings
export EDITOR=/usr/bin/vi
export PATH=$HOME/bin:$PATH
export TERM=xterm

# Environment variables
export WORKON_HOME=~/.virtualenvs
export PROJECT_HOME=~/projectes
export VIRTUALENVWRAPPER_VIRTUALENV_ARGS='--system-site-packages'
source /usr/bin/virtualenvwrapper.sh

#TRYTOND configuration
export TRYTOND_CONFIG=~/trytond.conf
export TRYTONPASSFILE=~/.default_tryton_password
export DB_CACHE=~/tryton_db_cache
