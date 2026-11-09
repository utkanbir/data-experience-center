import ast,unittest
from pathlib import Path
from decimal import Decimal

source=Path(__file__).resolve().parents[1]/'packages/rm9/experience/scenario.py'
tree=ast.parse(source.read_text())
functions=ast.Module(body=[node for node in tree.body if isinstance(node,ast.FunctionDef) and node.name in ('close_enough','evaluate_totals')],type_ignores=[])
scope={'Decimal':Decimal};exec(compile(functions,str(source),'exec'),scope)

class TotalsTest(unittest.TestCase):
    def rows(self):
        return [('2025-01-01','HoReCa',8164.8,1844.64),('2025-01-01','Retail',10000,1000),('2025-01-01','Other',9656,1000),('2025-02-01','HoReCa',3628.8,819.84),('2025-02-01','Retail',10000,1000),('2025-02-01','Other',9656,1000)]
    def test_actual_reference(self):
        checks,metrics=scope['evaluate_totals'](self.rows());self.assertTrue(all(checks.values()));self.assertEqual(metrics['change'],-4536)
    def test_wrong_revenue_is_not_success(self):
        rows=self.rows();rows[0]=('2025-01-01','HoReCa',9000,1844.64);checks,_=scope['evaluate_totals'](rows);self.assertFalse(checks['horeca']);self.assertFalse(checks['months']);self.assertFalse(checks['price'])
    def test_duplicate_is_rejected(self):
        with self.assertRaises(ValueError):scope['evaluate_totals'](self.rows()+[self.rows()[0]])
    def test_missing_channel_is_rejected(self):
        with self.assertRaises(ValueError):scope['evaluate_totals'](self.rows()[:-1])
    def test_zero_liters_is_not_a_valid_price(self):
        rows=self.rows();rows[0]=('2025-01-01','HoReCa',8164.8,0)
        with self.assertRaises(Exception):scope['evaluate_totals'](rows)

if __name__=='__main__':unittest.main()
