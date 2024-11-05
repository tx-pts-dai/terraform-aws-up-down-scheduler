import pytest
from datetime import datetime
from main import is_day_before_patching

test_dates = {
    "2024-01-01": True,  # day before patching
    "2024-01-02": False,  # patching
    "2024-04-01": True,  # day before patching
    "2024-04-02": False,  # patching
    "2024-07-01": True,  # day before patching
    "2024-07-02": False,  # patching
    "2024-09-30": True,  # day before patching
    "2024-10-01": False,  # patching
    "2024-10-07": False,  # random wrong date
    "2024-10-08": False,  # random wrong date
    "2025-01-06": True,  # day before patching
    "2025-01-07": False,  # patching
    "2025-03-31": True,  # day before patching
    "2025-04-01": False,  # patching
    "2025-06-30": True,  # day before patching
    "2025-07-01": False,  # patching
    "2025-10-06": True,  # day before patching
    "2025-10-07": False,  # patching
    "2025-10-08": False,  # random wrong date
    "2025-12-31": False,  # random wrong date
}


@pytest.mark.parametrize("date_str, expected", test_dates.items())
def test_is_day_before_patching(date_str, expected):
    date_to_check = datetime.strptime(date_str, "%Y-%m-%d").date()
    result = is_day_before_patching(date_to_check)
    assert (
        result == expected
    ), f"Date: {date_str}, Expected: {expected}, Result: {result}, ----> PASS: {result == expected}"
