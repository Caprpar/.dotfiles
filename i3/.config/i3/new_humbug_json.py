#!/usr/bin/env python3

import os
import re
import subprocess
import uuid
from faker import Faker


def main() -> None:
    faker = Faker()
    phrase = faker.catch_phrase().lower()
    slug = re.sub(r"[^a-z0-9]+", "-", phrase).strip("-") or "humbug"
    name = f"{slug}-{uuid.uuid4().hex[:6]}.json"

    target_dir = "/tmp/jsons"
    os.makedirs(target_dir, exist_ok=True)

    path = os.path.join(target_dir, name)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(f"// filename: {name}\n")

    subprocess.run(["kitty", "nvim", path], check=False)


if __name__ == "__main__":
    main()
