// The rows of a CSV text, one for each line. A row holds the fields of
// its line, in order.

export type Row = string[];

// isQuoted: the field starts and ends with a double quote.
export function isQuoted(field: string): boolean {
  return field.length >= 2 && field.startsWith('"') && field.endsWith('"');
}

// unquote: the field without its double quotes.
export function unquote(field: string): string {
  if (!isQuoted(field)) {
    return field;
  }

  return field.slice(1, -1).replaceAll('""', '"');
}

// trimRow: each field of the row without spaces at its ends.
export function trimRow(row: Row): Row {
  return row.map((field) => {
    return field.trim();
  });
}

// width: the count of fields of the widest row.
export function width(rows: Row[]): number {
  let widest = 0;
  for (const row of rows) {
    widest = Math.max(widest, row.length);
  }

  return widest;
}

// countRows: the count of lines of the text.
export function countRows(text: string): number {
  let count = 1;
  for (const char of text) {
    if (char === '\n') {
      count += 1;
    }
  }

  return count;
}

// isEmpty: the row has no field with a character.
export function isEmpty(row: Row): boolean {
  return row.every((field) => {
    return field === '';
  });
}

// parseRows: the rows of a CSV text, one for each line.
export function parseRows(text: string): Row[] {
  const rows: Row[] = [];
  for (const line of text.split('\n')) {
    rows.push(line.split(/[,\t]/).map(unquote));
  }

  return rows;
}
