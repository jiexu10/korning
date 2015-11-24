# Use this file to import the sales information into the
# the database.

require "pg"
require "csv"
require "pry"

def parse_info(info_string)
  info_string.scan(/(.+)\s[(](.+)[)]/).flatten.reverse
end

def import_csv_data
  all_data = []
  CSV.foreach('sales.csv', headers: true, header_converters: :symbol) do |row|
    all_data << row.to_hash
  end
  all_data
end

def make_sql_hash(sql_query, data)
  pass_to_sql = {}
  pass_to_sql[:sql_query] = sql_query
  pass_to_sql[:data] = data
  pass_to_sql
end

def make_employee_data
  employees = []
  import_csv_data.each do |row_hash|
    employee_data = parse_info(row_hash[:employee])
    employee_data_hash = { email: employee_data.first, name: employee_data.last }
    employees << employee_data_hash
  end
  employees
end

def employee_to_db
  sql_query = %(
  INSERT INTO employees (email, name)
  VALUES ($1, $2)
  )
  data = []
  make_employee_data.uniq!.each do |info|
    data << [info[:email], info[:name]]
  end
  make_sql_hash(sql_query, data)
end

def make_customer_data
  customers = []
  import_csv_data.each do |row_hash|
    customer_data = parse_info(row_hash[:customer_and_account_no])
    customer_data_hash = { account_no: customer_data.first, name: customer_data.last }
    customers << customer_data_hash
  end
  customers
end

def customer_to_db
  sql_query = %(
  INSERT INTO customers (account_no, name)
  VALUES ($1, $2)
  )
  data = []
  make_customer_data.uniq!.each do |info|
    data << [info[:account_no], info[:name]]
  end
  make_sql_hash(sql_query, data)
end

def make_product_name
  products = []
  import_csv_data.each do |row_hash|
    product_data_hash = { name: row_hash[:product_name] }
    products << product_data_hash
  end
  products
end

def product_to_db
  sql_query = %(
  INSERT INTO products (name)
  VALUES ($1)
  )
  data = []
  make_product_name.uniq!.each do |info|
    data << [info[:name]]
  end
  make_sql_hash(sql_query, data)
end

def make_frequency
  frequency = []
  import_csv_data.each do |row_hash|
    frequency_data_hash = { frequency: row_hash[:invoice_frequency] }
    frequency << frequency_data_hash
  end
  frequency
end

def frequency_to_db
  sql_query = %(
  INSERT INTO invoice_freq (frequency)
  VALUES ($1)
  )
  data = []
  make_frequency.uniq!.each do |info|
    data << [info[:frequency]]
  end
  make_sql_hash(sql_query, data)
end

def get_fkey_query(table, column, identifier_string)
  sql_query = %(
  SELECT id
  FROM #{table}
  WHERE #{table}.#{column} = '#{identifier_string}';
  )
end

def make_sales_data
  # sale_date,sale_amount,units_sold,invoice_no, employee_id, customer_id, product_id, frequency_id
  sales = []
  import_csv_data.each do |row_hash|
    sales_data_hash = { sale_date: row_hash[:sale_date], sale_amount: row_hash[:sale_amount], units_sold: row_hash[:units_sold], invoice_no: row_hash[:invoice_no] }
    sales << sales_data_hash
  end
  sales
end

def sales_to_db(data)
  sql_query = %(
  INSERT INTO sales_info (invoice_num, sale_date, sale_amount, units_sold, employee_id, customer_id, product_id, frequency_id)
  VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
  )
  make_sql_hash(sql_query, data)
end

def add_db_data
  db_connection do |conn|
    employee_to_db[:data].each do |data|
      conn.exec_params(employee_to_db[:sql_query], data)
    end
    customer_to_db[:data].each do |data|
      conn.exec_params(customer_to_db[:sql_query], data)
    end
    product_to_db[:data].each do |data|
      conn.exec_params(product_to_db[:sql_query], data)
    end
    frequency_to_db[:data].each do |data|
      conn.exec_params(frequency_to_db[:sql_query], data)
    end


    import_csv_data.each do |row_hash|
      employee_data = parse_info(row_hash[:employee])
      employee_data_hash = { email: employee_data.first, name: employee_data.last }
      employee_query = get_fkey_query("employees", "email", employee_data_hash[:email])
      employee_id = conn.exec(employee_query).first["id"]

      customer_data = parse_info(row_hash[:customer_and_account_no])
      customer_data_hash = { account_no: customer_data.first, name: customer_data.last }
      customer_query = get_fkey_query("customers", "account_no", customer_data_hash[:account_no])
      customer_id = conn.exec(customer_query).first["id"]

      product_query = get_fkey_query("products", "name", row_hash[:product_name])
      product_id = conn.exec(product_query).first["id"]

      frequency_query = get_fkey_query("invoice_freq", "frequency", row_hash[:invoice_frequency])
      frequency_id = conn.exec(frequency_query).first["id"]

      sales = []
      sales << [row_hash[:sale_date], row_hash[:sale_amount][1..-1], row_hash[:units_sold], row_hash[:invoice_no], employee_id, customer_id, product_id, frequency_id]
      sql_query = %(
      INSERT INTO sales_info (sale_date, sale_amount, units_sold, invoice_no, employee_id, customer_id, product_id, frequency_id)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      )

      conn.exec_params(sql_query, sales.flatten)
    end
  end
end

def db_connection
  begin
    connection = PG.connect(dbname: "korning")
    yield(connection)
  ensure
    connection.close
  end
end

add_db_data
