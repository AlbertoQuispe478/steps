require("dotenv").config();
const app = require("./app");
const { sequelize } = require("./config/db");
const logger = require("./utils/logger");

const PORT = process.env.PORT || 3000;

async function iniciar() {
  try {
    await sequelize.authenticate();
    logger.info("Database connected successfully");

    app.listen(PORT, () => {
      logger.info(`Server is running on port ${PORT}`);
    });
  } catch (error) {
    logger.error("Error al conectar la base de datos:", error);
    process.exit(1);
  }
}

iniciar();
