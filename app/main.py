from flask import Flask, render_template_string
import pymysql
import os

app = Flask(__name__)

DB_CONFIG = {
    'host': os.environ.get('DB_HOST', 'localhost'),
    'user': os.environ.get('DB_USER', 'sadmin'),
    'password': os.environ.get('DB_PASSWORD', ''),
    'database': os.environ.get('DB_NAME', 'app'),
    'ssl_ca': os.environ.get('DB_SSL_CA', '/app/root.crt')
}

HTML = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Проверка MySQL</title>
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; }
        .success { color: green; font-size: 24px; }
        .error { color: red; font-size: 18px; }
        button { padding: 10px 20px; font-size: 16px; cursor: pointer; }
    </style>
</head>
<body>
    <h1>Проверка подключения к MySQL</h1>
    <button onclick="location.reload()">Проверить</button>
    <div class="{{ 'success' if success else 'error' }}">
        <p>{{ msg }}</p>
    </div>
</body>
</html>
'''

@app.route('/')
def index():
    try:
        conn = pymysql.connect(
            host=DB_CONFIG['host'],
            user=DB_CONFIG['user'],
            password=DB_CONFIG['password'],
            database=DB_CONFIG['database'],
            ssl={'ca': './root.crt'}
        )
        conn.close()
        msg = f'✅ Успешно подключено к БД {DB_CONFIG["database"]} на {DB_CONFIG["host"]}'
        success = True
    except Exception as e:
        msg = f'❌ Ошибка: {e}'
        success = False
    
    return render_template_string(HTML, msg=msg, success=success)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)