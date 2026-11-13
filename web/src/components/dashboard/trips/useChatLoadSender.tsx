'use client';

import * as React from 'react';
import { toast } from 'react-toastify';

import { useSendLoadTextMutation } from '@/redux/TripApiSlice';

import { LoadAnswers, LoadQuestion, LoadQuestionDialog } from './LoadQuestionDialog';
import { loadNoIn } from './loadText';

/**
 * A load pasted in a chat box goes out as a load (the driver gets the standard load message only when
 * it's really sent — never the pasted text). The server may ask first (driver busy / lined up / leg
 * open): the same questions as the driver's chat. Returns send() and the question dialog to render.
 */
export function useChatLoadSender({ driverId, driverName, onSent }: { driverId: string | null; driverName?: string | null; onSent?: () => void }) {
  const [sendLoadText, { isLoading: sending }] = useSendLoadTextMutation();
  const [question, setQuestion] = React.useState<LoadQuestion | null>(null);
  const [answers, setAnswers] = React.useState<LoadAnswers>({});
  const [text, setText] = React.useState('');

  const send = React.useCallback(
    async (body: string, given: LoadAnswers = {}) => {
      if (!driverId) {
        toast.error('No driver on this truck — add the driver to the truck, or use Send load and pick one', { autoClose: 10000 });
        return;
      }
      try {
        const res = await sendLoadText({ text: body, driverProfileId: driverId, ...given }).unwrap();
        toast.success(res.message || 'Load sent');
        setQuestion(null);
        setAnswers({});
        onSent?.();
      } catch (err: any) {
        if (err?.status === 409 && err?.data?.needs) {
          setText(body);
          setAnswers(given);
          setQuestion({ needs: err.data.needs, info: err.data.info || {} });
          return;
        }
        toast.error(err?.data?.message || 'Could not send the load', { autoClose: 10000 });
      }
    },
    [driverId, sendLoadText, onSent]
  );

  const dialog = (
    <LoadQuestionDialog
      question={question}
      loadNo={loadNoIn(text) || ''}
      driverName={driverName || 'the driver'}
      busy={sending}
      onClose={() => setQuestion(null)}
      onAnswer={(a) => {
        setQuestion(null);
        void send(text, { ...answers, ...a });
      }}
    />
  );
  return { send, sending, dialog };
}
