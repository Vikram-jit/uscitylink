import React from 'react';
import {
  List,
  ListItem,
  ListItemText,
  IconButton,
  Paper,
  Typography,
  Box,
} from '@mui/material';
import { Edit as EditIcon, Delete as DeleteIcon } from '@mui/icons-material';
import { Question } from './EditTraining';

interface QuestionListProps {
  questions: Question[];
  onEdit: (question: Question) => void;
  onDelete: (id: string) => void;
}

export default function QuestionList({ questions, onEdit, onDelete }: QuestionListProps) {
  return (
    <Paper elevation={3} sx={{ mt: 3, p: 2 }}>
      <Typography variant="h6" gutterBottom>
        Questions ({questions.filter((e)=>!e.isDeleted).length})
      </Typography>
      <List>
        {questions?.filter((item) => !item.isDeleted)?.map((question) => (
          <ListItem
            key={question.id}
            sx={{
              border: '1px solid #e0e0e0',
              borderRadius: 1,
              mb: 1,
              flexDirection: 'column',
              alignItems: 'stretch',
            }}
          >
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', width: '100%' }}>
              <ListItemText
                primary={question.text}
                secondary={
                  <Box sx={{ mt: 1 }}>
                    {question.options.map((option, index) => (
                      <Typography
                        key={option.id}
                        variant="body2"
                        color={option.isCorrect ? 'success.main' : 'text.secondary'}
                        sx={{ ml: 2 }}
                      >
                        {index + 1}. {option.text} {option.isCorrect && ' (✓)'}
                      </Typography>
                    ))}
                  </Box>
                }
              />
              <Box>
                {/* <IconButton onClick={() => onEdit(question)} color="primary">
                  <EditIcon />
                </IconButton> */}
                <IconButton onClick={() => onDelete(question.id)} color="error">
                  <DeleteIcon />
                </IconButton>
              </Box>
            </Box>
          </ListItem>
        ))}
      </List>
    </Paper>
  );
}