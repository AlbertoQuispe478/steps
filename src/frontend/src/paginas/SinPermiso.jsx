import { useLocation, Link } from 'react-router-dom';

export default function SinPermiso() {
  const { state } = useLocation();
  return (
    <div className="tarjeta mx-auto max-w-md p-10 text-center">
      <h2 className="text-lg font-bold">Sección no habilitada</h2>
      <p className="mt-1 text-sm text-suave">Permiso necesario: <b>{state?.funcion ?? 'desconocido'}</b></p>
      <Link to="/" className="btn mt-4 inline-block">Volver al inicio</Link>
    </div>
  );
}
