from envparse import env

DB_HOST = env.str('DB_HOST', default='keys-db.cjjdbsrwo4o8.us-west-2.rds.amazonaws.com')#'db.cloud-up-insight.com')
DB_USER = env.str('DB_USER', default='root')
DB_PASSWD = env.str('DB_PASSWD', default='notewhispererkeys')

MSG_DB_NAME = env.str('MSG_DB_NAME', default='msg_db')
KEY_DB_NAME = env.str('KEY_DB_NAME', default='keys_db')