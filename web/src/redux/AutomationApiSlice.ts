import { apiSlice } from './apiSlice';
import type {
  BuilderMeta,
  DocType,
  DocTypeExample,
  DocumentAnalysis,
  Flow,
  FlowRun,
  MessageDocument,
  Pagination,
  TestFlowResult,
  UsageReport,
  AutomationSettings,
  AutomationSettingsUpdate,
  ScaleCheck,
  WeightRuleSet,
  EquipmentProfile,
  DriverTrip,
} from './models/AutomationModel';

interface Res<T> {
  status: boolean;
  message?: string;
  data: T;
}

export const AutomationApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getAutomationMe: builder.query<Res<{ role: string | null; isAdmin: boolean; isStaff?: boolean }>, void>({
      query: () => ({ url: 'automation/me', method: 'GET' }),
    }),

    // Doc types
    getDocTypes: builder.query<Res<DocType[]>, void>({
      query: () => ({ url: 'automation/doc-types', method: 'GET' }),
      providesTags: ['docTypes'],
    }),
    getDocType: builder.query<Res<DocType>, { id: string }>({
      query: ({ id }) => ({ url: `automation/doc-types/${id}`, method: 'GET' }),
      providesTags: ['docTypes'],
    }),
    createDocType: builder.mutation<Res<DocType>, Partial<DocType>>({
      query: (body) => ({ url: 'automation/doc-types', method: 'POST', body }),
      invalidatesTags: ['docTypes', 'automationMeta'],
    }),
    updateDocType: builder.mutation<Res<DocType>, Partial<DocType> & { id: string }>({
      query: ({ id, ...body }) => ({ url: `automation/doc-types/${id}`, method: 'PUT', body }),
      invalidatesTags: ['docTypes', 'automationMeta'],
    }),
    getSuggestedKeywords: builder.query<
      Res<{ documents: number; suggestions: { word: string; docs: number }[] }>,
      { id: string }
    >({
      query: ({ id }) => ({ url: `automation/doc-types/${id}/suggested-keywords`, method: 'GET' }),
      keepUnusedDataFor: 0,
      providesTags: ['docTypes'],
    }),
    deleteDocType: builder.mutation<Res<null>, { id: string }>({
      query: ({ id }) => ({ url: `automation/doc-types/${id}`, method: 'DELETE' }),
      invalidatesTags: ['docTypes', 'automationMeta'],
    }),

    // Training examples
    extractSample: builder.mutation<Res<{ s3_key: string; analysis: DocumentAnalysis }>, FormData>({
      query: (body) => ({ url: 'automation/extract', method: 'POST', body }),
    }),
    createExample: builder.mutation<
      Res<DocTypeExample>,
      { docTypeId: string; s3_key: string; expected_fields: Record<string, any> }
    >({
      query: ({ docTypeId, ...body }) => ({
        url: `automation/doc-types/${docTypeId}/examples`,
        method: 'POST',
        body,
      }),
      invalidatesTags: ['docTypes', 'candidateExamples'],
    }),
    updateExample: builder.mutation<
      Res<DocTypeExample>,
      { id: string; expected_fields?: Record<string, any>; active?: boolean; doc_type_id?: string }
    >({
      query: ({ id, ...body }) => ({ url: `automation/examples/${id}`, method: 'PUT', body }),
      invalidatesTags: ['docTypes', 'candidateExamples'],
    }),
    deleteExample: builder.mutation<Res<null>, { id: string }>({
      query: ({ id }) => ({ url: `automation/examples/${id}`, method: 'DELETE' }),
      invalidatesTags: ['docTypes', 'candidateExamples'],
    }),
    getCandidateExamples: builder.query<Res<DocTypeExample[]>, void>({
      query: () => ({ url: 'automation/examples/candidates', method: 'GET' }),
      providesTags: ['candidateExamples'],
    }),

    // Flows
    getBuilderMeta: builder.query<Res<BuilderMeta>, void>({
      query: () => ({ url: 'automation/meta', method: 'GET' }),
      providesTags: ['automationMeta'],
    }),
    getFlows: builder.query<Res<Flow[]>, void>({
      query: () => ({ url: 'automation/flows', method: 'GET' }),
      providesTags: ['flows'],
    }),
    getFlow: builder.query<Res<Flow>, { id: string }>({
      query: ({ id }) => ({ url: `automation/flows/${id}`, method: 'GET' }),
      providesTags: ['flows'],
    }),
    createFlow: builder.mutation<Res<Flow>, Partial<Flow>>({
      query: (body) => ({ url: 'automation/flows', method: 'POST', body }),
      invalidatesTags: ['flows'],
    }),
    updateFlow: builder.mutation<Res<Flow>, Partial<Flow> & { id: string }>({
      query: ({ id, ...body }) => ({ url: `automation/flows/${id}`, method: 'PUT', body }),
      invalidatesTags: ['flows'],
    }),
    toggleFlow: builder.mutation<Res<Flow>, { id: string; active?: boolean; shadow_mode?: boolean }>({
      query: ({ id, ...body }) => ({ url: `automation/flows/${id}/toggle`, method: 'PATCH', body }),
      invalidatesTags: ['flows'],
    }),
    deleteFlow: builder.mutation<Res<null>, { id: string }>({
      query: ({ id }) => ({ url: `automation/flows/${id}`, method: 'DELETE' }),
      invalidatesTags: ['flows'],
    }),
    testFlow: builder.mutation<Res<TestFlowResult>, FormData>({
      query: (body) => ({ url: 'automation/flows/test', method: 'POST', body }),
    }),

    // Monitoring
    getFlowRuns: builder.query<
      Res<{ runs: FlowRun[]; pagination: Pagination }>,
      { page: number; flowId?: string; matched?: string; errorsOnly?: boolean }
    >({
      query: ({ page, flowId = '', matched = '', errorsOnly = false }) => ({
        url: `automation/runs?page=${page}&flowId=${flowId}&matched=${matched}&errorsOnly=${errorsOnly}`,
        method: 'GET',
      }),
      keepUnusedDataFor: 0,
      providesTags: ['flowRuns'],
    }),
    getReviewQueue: builder.query<Res<{ documents: MessageDocument[]; pagination: Pagination }>, { page: number }>({
      query: ({ page }) => ({ url: `automation/review-queue?page=${page}`, method: 'GET' }),
      keepUnusedDataFor: 0,
      providesTags: ['reviewQueue'],
    }),
    getAutomationStats: builder.query<
      Res<{
        days: number;
        byType: { doc_type_key: string | null; status: string; count: number; avgConfidence: number | null; inputTokens: number | null; outputTokens: number | null }[];
        corrections: number;
        matchedRuns: number;
      }>,
      { days: number }
    >({
      query: ({ days }) => ({ url: `automation/stats?days=${days}`, method: 'GET' }),
      keepUnusedDataFor: 0,
    }),

    getUsageReport: builder.query<Res<UsageReport>, { days: number }>({
      query: ({ days }) => ({ url: `automation/usage?days=${days}`, method: 'GET' }),
      keepUnusedDataFor: 0,
    }),

    getAutomationSettings: builder.query<Res<AutomationSettings>, void>({
      query: () => ({ url: 'automation/settings', method: 'GET' }),
      keepUnusedDataFor: 0,
    }),
    updateAutomationSettings: builder.mutation<Res<{ model?: string }>, AutomationSettingsUpdate>({
      query: (body) => ({ url: 'automation/settings', method: 'PUT', body }),
    }),

    // Staff: chat attachments
    getScaleChecks: builder.query<
      Res<{ checks: ScaleCheck[]; pending: number; pagination: { page: number; pageSize: number; total: number } }>,
      { page: number; approval?: string; status?: string }
    >({
      query: ({ page, approval, status }) => ({
        url: `automation/scale-checks?page=${page}${approval ? `&approval=${approval}` : ''}${status ? `&status=${status}` : ''}`,
        method: 'GET',
      }),
      keepUnusedDataFor: 0,
      providesTags: ['scaleChecks'],
    }),
    decideScaleCheck: builder.mutation<Res<ScaleCheck>, { id: string; messageId: string; decision: 'approve' | 'reject'; note?: string }>({
      query: ({ id, decision, note }) => ({ url: `automation/scale-checks/${id}/${decision}`, method: 'POST', body: { note } }),
      invalidatesTags: (_r, _e, { messageId }) => ['scaleChecks', { type: 'messageDocument', id: messageId }],
    }),
    recheckScaleCheck: builder.mutation<Res<ScaleCheck>, { id: string; messageId: string }>({
      query: ({ id }) => ({ url: `automation/scale-checks/${id}/recheck`, method: 'POST' }),
      invalidatesTags: (_r, _e, { messageId }) => ['scaleChecks', { type: 'messageDocument', id: messageId }],
    }),
    recordScaleAdjustment: builder.mutation<
      Res<ScaleCheck>,
      { id: string; messageId: string; action: string; holes?: number | null; parked_confirmed: boolean }
    >({
      query: ({ id, messageId: _m, ...body }) => ({ url: `automation/scale-checks/${id}/adjustment`, method: 'POST', body }),
      invalidatesTags: (_r, _e, { messageId }) => ['scaleChecks', { type: 'messageDocument', id: messageId }],
    }),
    getScaleReport: builder.query<Res<any>, { id: string }>({
      query: ({ id }) => ({ url: `automation/scale-checks/${id}/report`, method: 'GET' }),
      keepUnusedDataFor: 0,
    }),
    reviewRuleSet: builder.mutation<Res<WeightRuleSet>, { id: string }>({
      query: ({ id }) => ({ url: `automation/rule-sets/${id}/review`, method: 'POST' }),
      invalidatesTags: ['ruleSets'],
    }),
    getEquipment: builder.query<Res<EquipmentProfile[]>, void>({
      query: () => ({ url: 'automation/equipment', method: 'GET' }),
      providesTags: ['equipment'],
    }),
    saveEquipment: builder.mutation<Res<EquipmentProfile>, Partial<EquipmentProfile>>({
      query: ({ id, ...body }) => ({ url: id ? `automation/equipment/${id}` : 'automation/equipment', method: id ? 'PUT' : 'POST', body }),
      invalidatesTags: ['equipment', 'scaleChecks', 'messageDocument'],
    }),
    deleteEquipment: builder.mutation<Res<null>, { id: string }>({
      query: ({ id }) => ({ url: `automation/equipment/${id}`, method: 'DELETE' }),
      invalidatesTags: ['equipment'],
    }),
    importEquipment: builder.mutation<Res<null>, { csv: string }>({
      query: (body) => ({ url: 'automation/equipment/import', method: 'POST', body }),
      invalidatesTags: ['equipment'],
    }),
    getTrips: builder.query<Res<DriverTrip[]>, void>({
      query: () => ({ url: 'automation/trips', method: 'GET' }),
      providesTags: ['trips'],
    }),
    getDriverTrip: builder.query<Res<DriverTrip | null>, { driverId: string }>({
      query: ({ driverId }) => ({ url: `automation/trips/driver/${driverId}`, method: 'GET' }),
      providesTags: (_r, _e, { driverId }) => [{ type: 'trips', id: driverId }],
    }),
    saveDriverTrip: builder.mutation<Res<DriverTrip>, { driverId: string } & DriverTrip>({
      query: ({ driverId, ...body }) => ({ url: `automation/trips/driver/${driverId}`, method: 'PUT', body }),
      invalidatesTags: ['trips', 'scaleChecks', 'messageDocument'],
    }),
    closeDriverTrip: builder.mutation<Res<null>, { driverId: string }>({
      query: ({ driverId }) => ({ url: `automation/trips/driver/${driverId}/close`, method: 'POST' }),
      invalidatesTags: ['trips'],
    }),
    getRuleSets: builder.query<Res<WeightRuleSet[]>, void>({
      query: () => ({ url: 'automation/rule-sets', method: 'GET' }),
      providesTags: ['ruleSets'],
    }),
    createRuleSetVersion: builder.mutation<Res<WeightRuleSet>, Partial<WeightRuleSet> & { baseId?: string; notes: string }>({
      query: (body) => ({ url: 'automation/rule-sets', method: 'POST', body }),
      invalidatesTags: ['ruleSets'],
    }),
    getMessageDocument: builder.query<Res<MessageDocument | null>, { messageId: string }>({
      query: ({ messageId }) => ({ url: `automation/message-documents/${messageId}`, method: 'GET' }),
      providesTags: (_result, _error, { messageId }) => [{ type: 'messageDocument', id: messageId }],
    }),
    correctMessageDocument: builder.mutation<
      Res<MessageDocument>,
      { id: string; messageId: string; doc_type_key: string; fields: Record<string, any>; save_as_example?: boolean }
    >({
      query: ({ id, messageId: _messageId, ...body }) => ({
        url: `automation/message-documents/${id}/correct`,
        method: 'POST',
        body,
      }),
      invalidatesTags: (_result, _error, { messageId }) => [
        { type: 'messageDocument', id: messageId },
        'reviewQueue',
        'candidateExamples',
      ],
    }),
    reanalyzeMessage: builder.mutation<Res<null>, { messageId: string }>({
      query: ({ messageId }) => ({ url: `automation/message-documents/${messageId}/reanalyze`, method: 'POST' }),
      invalidatesTags: (_result, _error, { messageId }) => [{ type: 'messageDocument', id: messageId }, 'reviewQueue'],
    }),
  }),
});

export const {
  useGetAutomationMeQuery,
  useGetDocTypesQuery,
  useGetDocTypeQuery,
  useCreateDocTypeMutation,
  useUpdateDocTypeMutation,
  useDeleteDocTypeMutation,
  useGetSuggestedKeywordsQuery,
  useExtractSampleMutation,
  useCreateExampleMutation,
  useUpdateExampleMutation,
  useDeleteExampleMutation,
  useGetCandidateExamplesQuery,
  useGetBuilderMetaQuery,
  useGetFlowsQuery,
  useGetFlowQuery,
  useCreateFlowMutation,
  useUpdateFlowMutation,
  useToggleFlowMutation,
  useDeleteFlowMutation,
  useTestFlowMutation,
  useGetFlowRunsQuery,
  useGetReviewQueueQuery,
  useGetAutomationStatsQuery,
  useGetUsageReportQuery,
  useGetAutomationSettingsQuery,
  useUpdateAutomationSettingsMutation,
  useGetMessageDocumentQuery,
  useCorrectMessageDocumentMutation,
  useReanalyzeMessageMutation,
  useGetScaleChecksQuery,
  useDecideScaleCheckMutation,
  useGetRuleSetsQuery,
  useCreateRuleSetVersionMutation,
  useRecheckScaleCheckMutation,
  useRecordScaleAdjustmentMutation,
  useLazyGetScaleReportQuery,
  useReviewRuleSetMutation,
  useGetEquipmentQuery,
  useSaveEquipmentMutation,
  useDeleteEquipmentMutation,
  useImportEquipmentMutation,
  useGetTripsQuery,
  useGetDriverTripQuery,
  useSaveDriverTripMutation,
  useCloseDriverTripMutation,
} = AutomationApiSlice;
