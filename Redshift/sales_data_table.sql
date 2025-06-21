-- Redshift table  in which Redshift loader job will load data.

create table  sale_data_tab(
    country VARCHAR(256),
    item_type VARCHAR(256),
    order_date DATE,
    order_id bigint,
    ship_date DATE,
    units_sold bigint,
    unit_price DOUBLE PRECISION,
    total_revenue DOUBLE PRECISION,
    total_cost DOUBLE PRECISION,
    total_profit DOUBLE PRECISION
);
