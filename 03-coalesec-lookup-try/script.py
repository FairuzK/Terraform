import json
def main():
    result = {
        "id": "some-id",
       # "description": "This is a sample result from the script."
    }
    print(json.dumps(result))

    if __name__ == "__main__":
        main()