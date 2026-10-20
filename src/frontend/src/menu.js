// Una entrada por función (tabla funcion). El código f debe coincidir con funcion.codigo de la BD.
export const MENU = [
  { f: 'dashboard',    ruta: '/',             ico: '📊', txt: 'Dashboard',          hu: 'HU-10' },
  { f: 'clientes',     ruta: '/clientes',     ico: '👤', txt: 'Clientes',           hu: 'HU-02' },
  { f: 'recepcion',    ruta: '/recepcion',    ico: '🚗', txt: 'Recepción',          hu: 'HU-03' },
  { f: 'ordenes',      ruta: '/ordenes',      ico: '📋', txt: 'Órdenes de trabajo', hu: 'HU-04' },
  { f: 'presupuestos', ruta: '/presupuestos', ico: '💰', txt: 'Presupuestos',       hu: 'HU-05' },
  { f: 'citas',        ruta: '/citas',        ico: '📅', txt: 'Citas',              hu: 'HU-07' },
  { f: 'inventario',   ruta: '/inventario',   ico: '🔧', txt: 'Inventario',         hu: 'HU-08' },
  { f: 'pagos',        ruta: '/pagos',        ico: '💳', txt: 'Pagos y facturas',   hu: 'HU-09' },
  { f: 'reportes',     ruta: '/reportes',     ico: '📈', txt: 'Reportes (BI)',      hu: 'HU-10' },
];
