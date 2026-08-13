"""Mock core-banking data — mirrors the Flutter app's hardcoded data exactly.

In production these functions would call the real core-banking APIs; every
tool handler goes through here, so nothing is ever fabricated by the LLM.
"""

from __future__ import annotations

ACCOUNTS = [
    {
        "id": "main",
        "name": "Main Account",
        "iban_masked": "SA **** **** **** 9012",
        "balance": 47320.84,
        "currency": "SAR",
    },
    {
        "id": "savings",
        "name": "Savings Account",
        "iban_masked": "SA **** **** **** 3344",
        "balance": 12850.00,
        "currency": "SAR",
    },
]

# Mirrors mockBeneficiaries in lib/features/transfer/models/mock_beneficiaries.dart
# exactly (same names, same masked account numbers) — every beneficiary the
# agent can find is one the user can actually see on the "select beneficiary"
# screen. "first"/"arabic" exist purely so natural-language messages like
# "حول لعمر" or "transfer to Omar" resolve without the full legal name.
# txn_count > 0 -> known beneficiary; 0 -> new (matters to the risk gate)
BENEFICIARIES = [
    {
        "name": "Omar Al-Saud", "first": "Omar", "arabic": "عمر",
        "account": "SA •••• •••• •••• 1123", "bank": "Ameen Bank", "txn_count": 11,
    },
    {
        "name": "Fatima Al-Harbi", "first": "Fatima", "arabic": "فاطمة",
        "account": "SA •••• •••• •••• 3344", "bank": "Ameen Bank", "txn_count": 8,
    },
    {
        "name": "Noura Al-Qahtani", "first": "Noura", "arabic": "نورة",
        "account": "SA •••• •••• •••• 5566", "bank": "Riyad Bank", "txn_count": 5,
    },
    {
        "name": "Hassan Al-Mutairi", "first": "Hassan", "arabic": "حسن",
        "account": "SA •••• •••• •••• 7788", "bank": "Al Rajhi Bank", "txn_count": 3,
    },
    {
        "name": "Zain Al-Dosari", "first": "Zain", "arabic": "زين",
        "account": "SA •••• •••• •••• 9900", "bank": "Ameen Bank", "txn_count": 0,
    },
]

# Mirrors savedBills in lib/features/bills/bill.dart
BILLS = [
    {
        "name": "Electricity Bill",
        "arabic": "فاتورة الكهرباء",
        "biller": "Saudi Electricity Company",
        "account_number": "1009457822",
        "amount": 320.50,
        "amount_display": "320.50 SAR",
        "due_date": "28 Jun 2026",
        "category": "newBill",
    },
    {
        "name": "Mobile Postpaid",
        "arabic": "فاتورة الجوال",
        "biller": "STC",
        "account_number": "055 *** 2345",
        "amount": 184.00,
        "amount_display": "184.00 SAR",
        "due_date": "30 Jun 2026",
        "category": "oneTimePayment",
    },
    {
        "name": "Traffic Violation",
        "arabic": "مخالفة مرورية",
        "biller": "Absher",
        "account_number": "Violation 889201",
        "amount": 150.00,
        "amount_display": "150.00 SAR",
        "due_date": "25 Jun 2026",
        "category": "trafficViolation",
    },
    {
        "name": "Passport Service",
        "arabic": "خدمة الجوازات",
        "biller": "Ministry of Interior",
        "account_number": "SADAD 042",
        "amount": 300.00,
        "amount_display": "300.00 SAR",
        "due_date": "02 Jul 2026",
        "category": "sadadGovernment",
    },
]

PRODUCTS = {
    "cards": [
        {"name": "Visa Signature", "type": "Visa Signature", "annual_fee": 500, "network": "VISA Signature"},
        {"name": "Visa Platinum", "type": "Visa Platinum", "annual_fee": 300, "network": "VISA Platinum"},
        {"name": "mada", "type": "mada", "annual_fee": 0, "network": "mada"},
    ],
    "accounts": [
        {"name": "Saving", "detail": "Profit-bearing savings account."},
        {"name": "Active", "detail": "Everyday current account."},
        {"name": "Family Account", "detail": "Shared account with sub-limits."},
    ],
    # Mirrors the _products list in lib/features/products/products_screen.dart —
    # these are the only bank products a user can actually apply for (via
    # ProductDetailsScreen -> ProductReviewScreen), each needing an amount +
    # duration in months. "financing" | "savings" | "insurance".
    "bank_products": [
        {"name": "Personal Finance", "arabic": "التمويل الشخصي", "category": "financing", "max_amount": 500000},
        {"name": "Home Finance", "arabic": "تمويل المسكن", "category": "financing", "max_amount": 3000000},
        {"name": "Auto Finance", "arabic": "تمويل السيارات", "category": "financing", "max_amount": 200000},
        {"name": "Saving Certificate", "arabic": "شهادة الادخار", "category": "savings", "max_amount": None},
        {"name": "Investment Portfolio", "arabic": "المحفظة الاستثمارية", "category": "savings", "max_amount": None},
        {"name": "Travel Insurance", "arabic": "تأمين السفر", "category": "insurance", "max_amount": None},
    ],
}

ACCOUNT_TYPES = ["Saving", "Active", "Family Account"]
CURRENCIES = ["SAR", "USD", "EUR", "GBP"]
# Mirrors CardTypeOption.all in lib/features/cards/models/card_type_option.dart —
# these are the only 3 cards Ameen actually lets a user hold.
CARD_TYPES = ["Visa Signature", "Visa Platinum", "mada"]
TRANSFER_REASONS = ["Bills", "Salary", "Gift", "Family Support", "Other"]

# Long list on purpose: exercises the 2KB tool_result cap.
TRANSACTIONS = [
    {
        "date": f"2026-06-{(i % 28) + 1:02d}",
        "description": d,
        "amount": a,
        "direction": "debit" if a < 0 else "credit",
    }
    for i, (d, a) in enumerate(
        [
            ("Salary - ACME Corp", 18500.00),
            ("Grocery - Panda", -412.35),
            ("Fuel - Aldrees", -180.00),
            ("Transfer to Omar", -500.00),
            ("STC Postpaid", -184.00),
            ("Restaurant - Najd Village", -260.75),
            ("Online - Amazon.sa", -329.99),
            ("Transfer from Lara", 1200.00),
            ("Electricity Bill", -320.50),
            ("Pharmacy - Nahdi", -95.60),
            ("Coffee - Barns", -28.00),
            ("Transfer to Fatima", -750.00),
            ("School Fees", -3500.00),
            ("Online - Noon", -214.50),
            ("Grocery - Tamimi", -388.20),
            ("Fuel - Petromin", -175.00),
            ("Gym Membership", -299.00),
            ("Transfer to Noura", -300.00),
            ("Water Bill", -86.40),
            ("Restaurant - Herfy", -54.00),
            ("Online - Jarir", -1120.00),
            ("Transfer from Hassan", 640.00),
            ("Mobile Recharge", -57.50),
            ("Grocery - Othaim", -276.80),
            ("Parking", -12.00),
            ("Streaming Subscription", -45.00),
            ("Transfer to Omar", -850.00),
            ("Bakery", -36.25),
            ("Taxi - Careem", -48.90),
            ("Clinic Visit", -350.00),
            ("Online - Shein", -189.75),
            ("Fuel - Sasco", -170.00),
            ("Grocery - Carrefour", -420.10),
            ("Transfer to Hassan", -260.00),
            ("Charity Donation", -100.00),
            ("Restaurant - AlBaik", -42.00),
        ]
    )
]

USER_PROFILE = {
    "avg_txn_amount_90d": 4000.0,  # 90-day average incl. salary + rent transfers
    "account_age_days": 1500,
    "txn_count_24h": 1,
}


def find_product(query: str) -> dict | None:
    q = (query or "").strip().lower()
    if not q:
        return None
    for p in PRODUCTS["bank_products"]:
        if q == p["name"].lower() or q == p["arabic"]:
            return p
    for p in PRODUCTS["bank_products"]:
        if p["name"].lower() in q or p["arabic"] in q or q in p["name"].lower():
            return p
    return None


def find_account(query: str | None) -> dict:
    if query:
        q = query.lower()
        for acc in ACCOUNTS:
            if q in acc["name"].lower() or q in acc["iban_masked"].lower() or q == acc["id"]:
                return acc
    return ACCOUNTS[0]


def find_beneficiary(query: str) -> dict | None:
    q = (query or "").strip().lower()
    if not q:
        return None
    for b in BENEFICIARIES:
        if (
            q == b["name"].lower()
            or q == b["first"].lower()
            or q == b["arabic"]
            or q == f"{b['name'].lower()} - {b['account'].lower()}"
        ):
            return b
    for b in BENEFICIARIES:
        if (
            b["name"].lower() in q
            or b["first"].lower() in q
            or b["arabic"] in q
            or b["account"][-4:] in q  # last 4 digits, e.g. "1123"
        ):
            return b
    return None


def find_bill(query: str) -> dict | None:
    q = (query or "").strip().lower()
    if not q:
        return None
    aliases = {
        "electricity": "Electricity Bill", "كهرباء": "Electricity Bill",
        "mobile": "Mobile Postpaid", "جوال": "Mobile Postpaid", "stc": "Mobile Postpaid",
        "traffic": "Traffic Violation", "مخالفة": "Traffic Violation",
        "passport": "Passport Service", "جواز": "Passport Service",
    }
    for alias, name in aliases.items():
        if alias in q:
            q = name.lower()
            break
    for bill in BILLS:
        if q in bill["name"].lower() or q in bill["arabic"] or q in bill["biller"].lower():
            return bill
    return None
