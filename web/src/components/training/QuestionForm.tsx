import React, { useState } from 'react';
import {
  Box,
  TextField,
  Button,
  IconButton,
  FormControlLabel,
  Checkbox,
  Typography,
  Paper,
} from '@mui/material';
import { Delete as DeleteIcon, Add as AddIcon } from '@mui/icons-material';
import { Option, Question } from './EditTraining';

interface QuestionFormProps {
  onSubmit: (question: Omit<Question, 'id'>) => void;
  initialQuestion?: Question;
  isEditing?: boolean;
}

export default function QuestionForm({ onSubmit, initialQuestion, isEditing = false }: QuestionFormProps) {
  const [questionText, setQuestionText] = useState(initialQuestion?.text || '');
  const [options, setOptions] = useState<any[]>(
    initialQuestion?.options.map(({ text, isCorrect }) => ({ text, isCorrect })) || 
    [{ text: '', isCorrect: false }, { text: '', isCorrect: false }]
  );

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit({
      text: questionText,
      options: options,
      isDeleted:false
    });
    if (!isEditing) {
      setQuestionText('');
      setOptions([{ text: '', isCorrect: false }, { text: '', isCorrect: false }]);
    }
  };

  const addOption = () => {
    setOptions([...options, { text: '', isCorrect: false }]);
  };

  const removeOption = (index: number) => {
    setOptions(options.filter((_, i) => i !== index));
  };

  const updateOption = (index: number, field: keyof Omit<Option, 'id'>, value: string | boolean) => {
    const newOptions = [...options];
    newOptions[index] = { ...newOptions[index], [field]: value };
    setOptions(newOptions);
  };

  return (
    <Paper elevation={3} sx={{ p: 3, mb: 3 }}>
      <Typography variant="h6" gutterBottom>
        {isEditing ? 'Edit Question' : 'Add New Question'}
      </Typography>
      <Box component="form" onSubmit={handleSubmit} sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        <TextField
          label="Question Text"
          value={questionText}
          onChange={(e) => setQuestionText(e.target.value)}
          required
          fullWidth
          multiline
          rows={2}
        />

        <Typography variant="subtitle1" sx={{ mt: 2 }}>Options</Typography>
        
        {options.map((option, index) => (
          <Box key={index} sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
            <TextField
              label={`Option ${index + 1}`}
              value={option.text}
              onChange={(e) => updateOption(index, 'text', e.target.value)}
              required
              fullWidth
            />
            <FormControlLabel
              control={
                <Checkbox
                  checked={option.isCorrect}
                  onChange={(e) => updateOption(index, 'isCorrect', e.target.checked)}
                />
              }
              label="Correct"
            />
            {options.length > 2 && (
              <IconButton onClick={() => removeOption(index)} color="error">
                <DeleteIcon />
              </IconButton>
            )}
          </Box>
        ))}

        <Button
          startIcon={<AddIcon />}
          onClick={addOption}
          variant="outlined"
          sx={{ mt: 1, alignSelf: 'flex-start' }}
        >
          Add Option
        </Button>

        <Button
          type="submit"
          variant="contained"
          color="primary"
          sx={{ mt: 2 }}
        >
          {isEditing ? 'Update Question' : 'Add Question'}
        </Button>
      </Box>
    </Paper>
  );
}