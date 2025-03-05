from azure.purview.scanning import PurviewClient
from azure.identity import DefaultAzureCredential
import re

# Initialize client
credential = DefaultAzureCredential()
client = PurviewClient(
    account_name="your-purview-account",
    credential=credential
)

def create_pii_classifier():
    # Custom credit card classifier with Luhn check
    client.classifiers.create_custom(
        name="EnhancedCreditCard",
        patterns=[
            {
                "pattern": r"\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14})\b",
                "description": "Credit Card Numbers",
                "confidenceLevel": "High",
                "validation": {
                    "luhnCheck": True,
                    "exclusions": ["4111-1111-1111-1111"]  # Test numbers
                }
            }
        ]
    )

def create_phi_classifier():
    # Medical record number pattern
    client.classifiers.create_custom(
        name="MedicalRecordNumber",
        patterns=[
            {
                "pattern": r"\bMRN-\d{8}-[A-Z]{3}\b",
                "description": "Medical Record Numbers",
                "confidenceLevel": "Medium",
                "context": {
                    "requiredKeywords": ["patient", "diagnosis"],
                    "exclusionKeywords": ["test", "sample"]
                }
            }
        ]
    )

def validate_classifiers():
    # Check classification accuracy
    test_data = {
        "valid_cc": "4111-1111-1111-1111 (should be excluded)",
        "real_cc": "4012-8888-8888-1881 (valid)",
        "mrn": "MRN-20230515-ABC"
    }
    
    for content in test_data.values():
        result = client.classifiers.classify_text(content)
        print(f"Classification for '{content}':")
        for match in result.matches:
            print(f"- {match.classifier_name} ({match.confidence}%)")

if __name__ == "__main__":
    create_pii_classifier()
    create_phi_classifier()
    validate_classifiers()
