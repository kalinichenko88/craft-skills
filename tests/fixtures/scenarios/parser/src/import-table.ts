import { splitLine } from './parser/split.ts';

// importTable: the table of a CSV file, one row for each line.
export function importTable(text: string): string[][] {
  return text.split('\n').map(splitLine);
}
