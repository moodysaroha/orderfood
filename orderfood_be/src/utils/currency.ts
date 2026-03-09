/**
 * Currency utilities for INR (Indian Rupee).
 * All monetary values are stored as integers in paise (1 INR = 100 paise)
 * to avoid floating-point precision issues.
 */

export function rupeesToPaise(rupees: number): number {
  return Math.round(rupees * 100);
}

export function paiseToRupees(paise: number): number {
  return paise / 100;
}

export function formatINR(rupees: number): string {
  return `₹${rupees.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

export function formatPaiseToINR(paise: number): string {
  const rupees = paiseToRupees(paise);
  return `₹${rupees.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

export function formatPaiseToINRCompact(paise: number): string {
  const rupees = paiseToRupees(paise);
  if (rupees >= 10000000) {
    return `₹${(rupees / 10000000).toFixed(2)} Cr`;
  }
  if (rupees >= 100000) {
    return `₹${(rupees / 100000).toFixed(2)} L`;
  }
  if (rupees >= 1000) {
    return `₹${(rupees / 1000).toFixed(1)}K`;
  }
  return formatPaiseToINR(paise);
}
