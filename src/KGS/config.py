from envparse import env

DB_HOST = env.str('DB_HOST', default='db.note-whisperer.com')
DB_USER = env.str('DB_USER', default='root')
DB_PASSWD = env.str('DB_PASSWD', default='notewhisperer')

KEY_DB_NAME = env.str('KEY_DB_NAME', default='keys_db')
MSG_DB_NAME = env.str('MSG_DB_NAME', default='msg_db')
