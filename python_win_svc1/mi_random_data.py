import pyodbc
import os


class MssqlConnector(object):
    """A context manager used to connect to MS SQL server"""

    def __init__(self, conn_str):
        self.connection_string = conn_str
        self.connection = None

    def __enter__(self):
        self.connection = pyodbc.connect(self.connection_string)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_tb is None:
            self.connection.commit()
        else:
            self.connection.rollback()
        self.connection.close()


def execute_stored_procedure():
    """Testing execution of a stored procedure"""

    with MssqlConnector(os.environ.get("ConnStrArtanisPy")) as connector:
        cursor = connector.connection.cursor()
        cursor.execute("EXEC dbo.miGenAllRandomData")
        # cursor.execute("SELECT count(*) as cnt FROM dbo.miTableSizes")
        # row = cursor.fetchone()
        # while row:
        #     print(row[0])
        #     row = cursor.fetchone()
