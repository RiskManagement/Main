            con.Open();
            SqlCommand myCom = new SqlCommand("UPDATE ConnectionStrings SET Servername = @v1, DatabaseName = @v2, SchemaName = @v3, TableName = @v4 WHERE ConnectionID = @v5", con);
            myCom.Parameters.Add(new SqlParameter("@v1", Convert.String(txt1.Text)));
            myCom.Parameters.Add(new SqlParameter("@v2", Convert.String(txt2.Text)));
            myCom.Parameters.Add(new SqlParameter("@v3", Convert.String(txt3.Text)));
            myCom.Parameters.Add(new SqlParameter("@v4", Convert.String(txt4.Text)));
            myCom.Parameters.Add(new SqlParameter("@v5", Convert.String(txt5.Text)));
            myCom.ExecuteNonQuery();
            con.Close();
