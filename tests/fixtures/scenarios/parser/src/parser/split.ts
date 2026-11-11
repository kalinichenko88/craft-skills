// splitLine: the fields of one line of a CSV text.
export function splitLine(line: string): string[] {
  const fields = line.split(',');
  if (fields[fields.length - 1] === '') {
    fields.pop();
  }

  return fields;
}
