"""Configuration management for DNT Watcher."""

import yaml


def load_cabins(config_file: str = "dnt_hytter.yaml"):
    """
    Load cabin configuration from YAML file.

    Args:
        config_file (str): Path to the YAML configuration file.

    Returns:
        list: A list of dictionaries containing cabin information.
              Each dict has keys: 'navn', 'url', 'beskrivelse'
    """
    with open(config_file, "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)

    return config.get("dnt_hytter", [])


def extract_cabin_id(url: str):
    """
    Extract the cabin ID from a DNT booking URL.

    Args:
        url (str): The booking URL (e.g., 'https://hyttebestilling.dnt.no/hytte/101297')

    Returns:
        str: The cabin ID (e.g., '101297')
    """
    return url.rstrip("/").split("/")[-1]
