#!/bin/bash
set -eux

config_fqdn=$(hostname --fqdn)

apt-get install -y --no-install-recommends vim
cat >/etc/vim/vimrc.local <<'EOF'
syntax on
set background=dark
set esckeys
set ruler
set laststatus=2
set nobackup
autocmd BufNewFile,BufRead Vagrantfile set ft=ruby
EOF

# install nginx to host the Thunderbird Autoconfiguration xml file.
# thunderbird will make a request alike:
#   GET /.well-known/autoconfig/mail/config-v1.1.xml?emailaddress=alice%40mail.vagrant
# see https://wiki.mozilla.org/Thunderbird:Autoconfiguration:ConfigFileFormat
# see https://developer.mozilla.org/en-US/docs/Mozilla/Thunderbird/Autoconfiguration
# see https://developer.mozilla.org/en-US/docs/Mozilla/Thunderbird/Autoconfiguration/FileFormat/HowTo
apt-get install -y --no-install-recommends nginx
cp -R /vagrant/public/{.well-known,*} /var/www/html
find /var/www/html \
    -type f \
    -not \( \
        -name '*.png' \
    \) \
    -exec sed -i -E "s,@@config_fqdn@@,$config_fqdn,g" {} \;

# send a test email from the command line.
echo Hello World | sendmail alice
# dump the received email directly from the server store.
sleep 2; cat /var/vmail/$config_fqdn/alice/new/*.mail

# send a non-authenticated test email from alice to bob.
# NB this should fail because the postfix server is requiring user authentication.
python3 /var/www/html/examples/python/smtp/send-mail/example.py

# send an authenticated test email from bob to alice.
python3 /var/www/html/examples/python/smtp/send-mail-with-authentication/example.py
# dump the received email directly from the server store.
sleep 2; cat /var/vmail/$config_fqdn/alice/new/*.mail

# list the messages on the alice imap account.
python3 /var/www/html/examples/python/imap/list-mail/example.py

# print software versions.
dpkg-query -f '${Package} ${Version}\n' -W dnsmasq
dpkg-query -f '${Package} ${Version}\n' -W postfix
dpkg-query -f '${Package} ${Version}\n' -W dovecot-imapd

# query records.
dig any $config_fqdn
dig mx $config_fqdn

# IP lookup.
dig -x $(hostname -I | awk '{print $2}')

# query an external record.
dig a ruilopes.com
