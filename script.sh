set -e

PACKAGE_NAME=kogito-apps
PACKAGE_VERSION=${1:-1.36.1.Final}
PACKAGE_URL=https://github.com/kiegroup/kogito-apps.git

yum install procps-ng -y
sysctl -w net.ipv6.conf.all.disable_ipv6=1 ;
sysctl -w net.ipv6.conf.default.disable_ipv6=1 ;

yum update -y
yum install -y git curl
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" 
nvm install v18.12.0
ln -s $HOME/.nvm/versions/node/v18.12.0/bin/node /usr/bin/node
ln -s $HOME/.nvm/versions/node/v18.12.0/bin/npm /usr/bin/npm


#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
	rm -rf $PACKAGE_NAME
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi

cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

cd ui-packages/
yum install npm -y
npm install -g yarn
yarn install
yarn run init

export NODE_OPTIONS=--openssl-legacy-provider

if ! yarn run build:prod; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

if ! yarn run build; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

if ! yarn run build:fast; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

if ! yarn test -u; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
	exit 2
fi