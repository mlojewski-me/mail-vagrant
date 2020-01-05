import smtplib

user = 'bob@@@config_fqdn@@'
password = 'password'

fromaddr = user
toaddrs = ('alice@@@config_fqdn@@',)
body = 'Test'

msg = 'From: %s\r\nTo: %s\r\n\r\n' % (fromaddr, ', '.join(toaddrs))
msg = msg + body
server = smtplib.SMTP('@@config_fqdn@@')
server.set_debuglevel(1)
server.starttls() # for SSL use the SMTP_SSL class instead of SMTP.
server.login(user, password)
server.sendmail(fromaddr, toaddrs, msg)
server.quit()