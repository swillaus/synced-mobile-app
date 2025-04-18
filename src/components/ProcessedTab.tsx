const ProcessedTab: React.FC = () => {
  // ...existing code...
  return (
    <RecordDetails
      // ...existing code...
      paidFrom={selectedRecord?.paymentAccountName || selectedRecord?.paidFrom || ''}
      // ...existing code...
    />
  );
};
