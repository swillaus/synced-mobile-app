interface RecordDetailsProps {
  // ...existing code...
  paidFrom?: string;
}

const RecordDetails: React.FC<RecordDetailsProps> = ({ record }) => {
  return (
    <View>
      // ...existing code...
      <View style={styles.fieldContainer}>
        <Text style={styles.label}>Paid From:</Text>
        <Text style={styles.value}>{record.paidFrom || 'N/A'}</Text>
      </View>
      // ...existing code...
    </View>
  );
};
