/** A fetch that answers each URL with the status that the table gives it. */
export function fakeFetch(statuses: Record<string, number>): typeof fetch {
  return async (input) => {
    const status = statuses[String(input)];
    if (status === undefined) throw new Error('no route');
    return new Response(null, { status });
  };
}
