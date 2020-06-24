from http.server import HTTPServer, BaseHTTPRequestHandler
import psycopg2

class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        try:
            conn = psycopg2.connect(host="10.34.85.10", database="monitoring", user="postgres")
        except:
            self.wfile.write(b'FAIL - DB not contactable')

        if conn is not None:
            cur = conn.cursor()
            cur.execute("select count(value) from monitoring where ts > now() - (5 * interval '1 minute')")
            count = cur.fetchone()[0]
            if count < 4:
                self.wfile.write(b'WARN - Less than 4 samples in the last 5 minutes.')
            else:
                cur.execute("select avg(value) from monitoring where ts > now() - (5 * interval '1 minute')")
                average = cur.fetchone()[0]
                if average < 46:
                    self.wfile.write(b'WARN - Average value is less than 46')
                else:
                    self.wfile.write(b'OK')

httpd = HTTPServer(('localhost', 8080), SimpleHTTPRequestHandler)
httpd.serve_forever()

