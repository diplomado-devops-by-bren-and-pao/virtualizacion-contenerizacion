from flask import Flask, jsonify
import psycopg2

app = Flask(__name__)


def get_connection():

    return psycopg2.connect(
        host="database",
        database="saludos_db",
        user="saludos_user",
        password="saludos_password",
        port=5432
    )


@app.route("/health", methods=["GET"])
def health():

    return jsonify({
        "status": "OK"
    })


@app.route("/saludo", methods=["GET"])
def saludo():

    try:

        connection = get_connection()

        cursor = connection.cursor()

        cursor.execute("""
            SELECT mensaje
            FROM saludos
            ORDER BY RANDOM()
            LIMIT 1;
        """)

        result = cursor.fetchone()

        cursor.close()
        connection.close()

        if result:

            return jsonify({
                "mensaje": result[0]
            })

        return jsonify({
            "mensaje": "No hay saludos disponibles"
        })

    except Exception as error:

        return jsonify({
            "error": str(error)
        }), 500


if __name__ == "__main__":

    app.run(
        host="0.0.0.0",
        port=5000
    )