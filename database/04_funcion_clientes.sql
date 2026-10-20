-- HU-02: nueva pantalla "Clientes" (una función por pantalla). Seguro de repetir.
-- Si la BD ya estaba levantada: docker exec -i steps-db psql -U steps -d steps < database/04_funcion_clientes.sql
INSERT INTO funcion (id_tipo_funcion, codigo, nombre, ruta, metodo_http)
SELECT id_tipo_funcion, 'clientes', 'Clientes', '/clientes', 'GET' FROM tipo_funcion WHERE codigo = 'PAN'
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO rol_funcion (id_rol, id_funcion)
SELECT r.id_rol, f.id_funcion FROM rol r JOIN funcion f ON f.codigo = 'clientes' WHERE r.codigo IN ('ADMIN','RECEP')
ON CONFLICT (id_rol, id_funcion) DO NOTHING;
