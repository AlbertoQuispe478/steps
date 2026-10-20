// Marcador de las pantallas que se construyen en sprints posteriores.
export default function Pendiente({ titulo, hu }) {
  return <div className="tarjeta p-10 text-center"><h2 className="text-lg font-bold">{titulo}</h2><p className="mt-1 text-sm text-suave">Se construye en {hu}.</p></div>;
}
