-- Sprint 3 (HU-05/06): el cliente también responde presupuestos; repuestos de ejemplo (los reutiliza HU-08).
INSERT INTO rol_funcion (id_rol, id_funcion)
SELECT r.id_rol, f.id_funcion FROM rol r JOIN funcion f ON f.codigo = 'presupuestos' WHERE r.codigo = 'CLIENTE'
ON CONFLICT (id_rol, id_funcion) DO NOTHING;

INSERT INTO repuesto (id_tipo_repuesto, codigo, nombre, stock_actual, stock_minimo, precio_compra, precio_venta)
SELECT t.id_tipo_repuesto, v.c, v.n, v.s, v.m, v.pc, v.pv FROM (VALUES
 ('FIL','FIL-001','Filtro de aceite',2,5,30,45),('FRE','FRE-012','Pastillas de freno',4,6,120,180),('ACE','ACE-003','Aceite 10W-40',1,4,85,120),
 ('ELE','ELE-005','Bujía',24,10,20,35),('MOT','MOT-008','Correa de distribución',8,3,220,320)) v(t,c,n,s,m,pc,pv)
JOIN tipo_repuesto t ON t.codigo = v.t ON CONFLICT (codigo) DO NOTHING;