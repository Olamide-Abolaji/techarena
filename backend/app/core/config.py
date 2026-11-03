from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    app_name: str = "TechArena API"
    app_env: str = "development"
    database_url: str = "postgresql://techarena:techarena_dev_password@localhost:5432/techarena"
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

settings = Settings()
