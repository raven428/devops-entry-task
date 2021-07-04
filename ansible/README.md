# Infra Ansible config
## Requirements
- `ssh-agent` with working private key to root accounts
- python version matched system python for `python*-libselinux` usage
- environment with modules from `ansible.txt`:

```
ansible==2.10.7
ansible-base==2.10.10
ansible-inventory-grapher==2.5.0
bcrypt==3.2.0
cffi==1.14.5
cryptography==3.4.7
distro==1.5.0
Jinja2==3.0.1
jmespath==0.10.0
MarkupSafe==2.0.1
packaging==20.9
passlib==1.7.4
pycparser==2.20
pyparsing==2.4.7
PyYAML==5.4.1
selinux==0.2.1
six==1.16.0
ssh-audit==2.4.0
```

## Preparation of `pyenv`

```
sudo yum groupinstall "Development Tools"
sudo yum install \
  bzip2-devel \
  keyutils-libs-devel \
  krb5-devel \
  libcom_err-devel \
  libffi-devel \
  libselinux-devel \
  libsepol-devel \
  libverto-devel \
  ncurses-devel \
  openssl-devel \
  pcre2-devel \
  platform-python-devel \
  policycoreutils-devel \
  python36-devel \
  readline-devel \
  selinux-policy-devel \
  sqlite-devel \
  zlib-devel
sudo groupadd -g 1122 pyenv
sudo useradd -u 1122 -g 1122 -d /usr/pyenv -s /bin/bash pyenv
sudo su pyenv
chmod 755 ~
curl -L \
  https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer |
  bash
export PATH="~pyenv/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"
pyenv install 3.7.10
pyenv virtualenv 3.7.10 ansible-2.10-3.7.10
source ~pyenv/.pyenv/versions/ansible-2.10-3.7.10/bin/activate
pip install --upgrade pip
pip install -r ansible.txt
```

## Preparation to `ansible-playbook`
From own account without any elevations:

```
git clone git@github.com:raven428/p2p-entry.git
export PATH="~pyenv/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"
# three lines above can be in ~/.bash_profile
source ~pyenv/.pyenv/versions/ansible-2.10-3.7.10/bin/activate
cd p2p-entry/ansible
```

### Running `ansible-playbook`
Apply single host filtering by tag:

```
ansible-playbook --check --diff site.yaml -i inventory/inventory.yaml --limit p2p-test --tags etc-access
```

Apply the whole configuration to all hosts:

```
ansible-playbook --diff site.yaml -i inventory/inventory.yaml
```

## Bonus offtopic: working with git submodules

### Add submodule

```
smp='ansible/roles/external/nginx-install'
git submodule add git@github.com:nginxinc/ansible-role-nginx.git ${smp}
git submodule set-branch --branch tags/0.19.1 -- ${smp}
git add .gitmodules
(cd ${smp} && git checkout tags/0.19.1)
```

### Purge submodule

```
smp='ansible/roles/external/nginx-install'
git submodule deinit -f ${smp}
git add .gitmodules
git reset HEAD -- ${smp}
git rm -f ${smp}
rm -rf .git/modules/${smp} ${smp}
```
