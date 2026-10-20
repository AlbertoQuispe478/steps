const { Sequelize, QueryTypes } = require("sequelize");

// Configuración de la conexión a PostgreSQL (Docker en el puerto 5433)
const sequelize = new Sequelize(
  process.env.DB_NAME || "steps",
  process.env.DB_USER || "steps",
  process.env.DB_PASSWORD || "steps_dev",
  {
    host: process.env.DB_HOST || "localhost",
    port: process.env.DB_PORT || 5433,
    dialect: "postgres",
    logging: false,
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000,
    },
  },
);

module.exports = { sequelize, QueryTypes };
