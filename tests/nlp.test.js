test('reorders common ISL phrases', async () => {
  const mod = await import('../src/nlp.js');
  const ISLGrammarProcessor = mod.ISLGrammarProcessor;
  const p = new ISLGrammarProcessor();
  expect(p.reorder(['I', 'GO', 'SCHOOL'])).toMatch(
    /going to school|I am going to school/i
  );
  expect(p.reorder(['WATER', 'I', 'WANT'])).toMatch(
    /I want water|I would like some water/i
  );
  expect(p.reorder(['THANK', 'YOU'])).toMatch(/thank you/i);
});
