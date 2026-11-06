'use client';

import React, { useState } from 'react';
import { useParams } from 'next/navigation';

import {
  Alert,
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Box,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  Divider,
  Grid,
  Pagination,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Typography,

} from '@mui/material';


import { useRouter } from 'next/navigation';
import Button from '@mui/material/Button';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';

import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import {
  useGetDriverProfileByIdQuery, useLazyGetDriverDocumentUrlQuery,
} from '@/redux/UserApiSlice';

const formatDate = (value?: string | null) => {
  if (!value) return '-';

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) return value;

  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: '2-digit',
    year: 'numeric',
  });
};

const formatMoney = (value?: number | string | null) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(Number(value || 0));
};

const formatValue = (value: any) => {
  if (value === null || value === undefined || value === '') {
    return '-';
  }

  return String(value);
};

export default function DriverProfilePage() {
  const params = useParams();
  const router = useRouter();
  const id = params.id as string;

  const [page, setPage] = useState(1);

  const [selectedDocument, setSelectedDocument] = useState<any>(null);

  const [getDriverDocumentUrl] = useLazyGetDriverDocumentUrlQuery();

  const { data, isLoading, isError, error } =
    useGetDriverProfileByIdQuery(
      {
        id,
        page,
        pageSize: 10,
      },
      {
        skip: !id,
      }
    );

  const result = data?.data;

  const handleViewDocument = async (doc: any) => {
    // Open immediately to prevent browser popup blocking
    const newTab = window.open('about:blank', '_blank');
  
    if (!newTab) {
      alert('Please allow popups to view documents.');
      return;
    }
  
    try {
      const response = await getDriverDocumentUrl({
        id: String(id),
        documentId: doc.id,
      }).unwrap();
  
      if (response?.data?.url) {
        newTab.location.href = response.data.url;
      } else {
        newTab.close();
        alert('Document URL not found.');
      }
    } catch (error) {
      newTab.close();
      console.error('Unable to open document:', error);
      alert('Unable to open document.');
    }
  };

  if (isLoading) {
    return (
      <Box
        display="flex"
        justifyContent="center"
        alignItems="center"
        minHeight="300px"
      >
        <CircularProgress />
      </Box>
    );
  }

  if (isError || !result) {
    return (
      <Alert severity="error">
        {(error as any)?.data?.message ||
          data?.message ||
          'Unable to load driver profile.'}
      </Alert>
    );
  }

  const { profile, driver, documents, incomeSummary, trips, pagination } =
    result;

  const user = profile?.user;

  return (
    <Box p={3}>
      <Button
          variant="outlined"
          startIcon={<ArrowBackIcon />}
          onClick={() => router.push('/dashboard/users/driver')}
          sx={{
              mb: 3,
              textTransform: 'none',
              borderRadius: 2,
          }}
      >
          Back to Drivers
      </Button>
      {/* Page heading */}
      <Stack
        direction={{ xs: 'column', sm: 'row' }}
        justifyContent="space-between"
        alignItems={{ xs: 'flex-start', sm: 'center' }}
        mb={3}
      >
        <Box>
          <Typography variant="h4">
            Driver Profile
          </Typography>

          <Typography color="text.secondary" mt={0.5}>
            Driver information, income, documents and trip history
          </Typography>
        </Box>
      </Stack>

      {/* Driver Information */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" mb={2}>
            Driver Information
          </Typography>

          <Grid container spacing={3}>
            <Grid item xs={12} md={4}>
              <Typography color="text.secondary" variant="body2">
                Driver Name
              </Typography>
              <Typography fontWeight={600}>
                {profile?.username || driver?.name || '-'}
              </Typography>
            </Grid>

            <Grid item xs={12} md={4}>
              <Typography color="text.secondary" variant="body2">
                Email
              </Typography>
              <Typography fontWeight={600}>
                {user?.email || '-'}
              </Typography>
            </Grid>

            <Grid item xs={12} md={4}>
              <Typography color="text.secondary" variant="body2">
                Phone Number
              </Typography>
              <Typography fontWeight={600}>
                {user?.phone_number || driver?.phone || '-'}
              </Typography>
            </Grid>

            <Grid item xs={12} md={4}>
              <Typography color="text.secondary" variant="body2">
                Driver Number
              </Typography>
              <Typography fontWeight={600}>
                {user?.driver_number || '-'}
              </Typography>
            </Grid>

            {/* <Grid item xs={12} md={4}>
              <Typography color="text.secondary" variant="body2">
                Yard Management Driver ID
              </Typography>
              <Typography fontWeight={600}>
                {user?.yard_id || '-'}
              </Typography>
            </Grid> */}

            <Grid item xs={12} md={4}>
              <Typography color="text.secondary" variant="body2">
                Status
              </Typography>
              <Chip
                label={profile?.status || user?.status || 'Unknown'}
                color={
                  profile?.status === 'active' ||
                  user?.status === 'active'
                    ? 'success'
                    : 'default'
                }
                size="small"
              />
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* Income Summary */}
      <Typography variant="h6" mb={2}>
        Income Summary
      </Typography>

      <Grid container spacing={2} mb={3}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="text.secondary" variant="body2">
                Total Income
              </Typography>
              <Typography variant="h5" fontWeight={700} mt={1}>
                {formatMoney(incomeSummary?.totalIncome)}
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="text.secondary" variant="body2">
                Total Deductions
              </Typography>
              <Typography variant="h5" fontWeight={700} mt={1}>
                {formatMoney(incomeSummary?.totalDeductions)}
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="text.secondary" variant="body2">
                Total Trips
              </Typography>
              <Typography variant="h5" fontWeight={700} mt={1}>
                {incomeSummary?.totalTrips || 0}
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="text.secondary" variant="body2">
                Total Mileage
              </Typography>
              <Typography variant="h5" fontWeight={700} mt={1}>
                {Number(incomeSummary?.totalMileage || 0).toLocaleString(
                  'en-US'
                )}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Documents */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" mb={2}>
            Driver Documents
          </Typography>

          {documents?.length ? (
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Document</TableCell>
                  <TableCell>Issue Date</TableCell>
                  <TableCell>Expiry Date</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell align="center">Action</TableCell>
                </TableRow>
              </TableHead>

              <TableBody>
                {documents.map((doc: any) => (
                  <TableRow key={doc.id}>
                    <TableCell>
                      {doc.title || 'Document'}
                    </TableCell>

                    <TableCell>
                      {formatDate(doc.issue_date)}
                    </TableCell>

                    <TableCell>
                      {formatDate(doc.expire_date)}
                    </TableCell>

                    <TableCell>
                      <Chip
                        size="small"
                        label={doc.expired_status || 'Valid'}
                        color={
                          doc.expired_status === 'Expired'
                            ? 'error'
                            : doc.expired_status === 'Expire Soon'
                              ? 'warning'
                              : 'success'
                        }
                      />
                    </TableCell>
                    <TableCell align="center">
                      {doc.file ? (
                        <Button
                          variant="contained"
                          size="small"
                          onClick={() => handleViewDocument(doc)}
                          sx={{ textTransform: 'none', borderRadius: 2 }}
                        >
                          View Document
                        </Button>
                      ) : (
                        '-'
                      )}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          ) : (
            <Typography color="text.secondary">
              No documents found.
            </Typography>
          )}
        </CardContent>
      </Card>


      {/* Trip Details */}
      <Card>
        <CardContent>
          <Stack
            direction={{ xs: 'column', sm: 'row' }}
            justifyContent="space-between"
            alignItems={{ xs: 'flex-start', sm: 'center' }}
            mb={2}
          >
            <Typography variant="h6">
              Trip Details
            </Typography>

            <Typography color="text.secondary" variant="body2">
              {pagination?.totalItems || 0} records
            </Typography>
          </Stack>

          {trips?.length ? (
            <Stack spacing={2}>
              {trips.map((trip: any) => (
                <Accordion key={trip.driver_pay_id}>
                  <AccordionSummary
                    expandIcon={<ExpandMoreIcon />}
                  >
                    <Grid container spacing={2} alignItems="center">
                      <Grid item xs={12} sm={3}>
                        <Typography fontWeight={600}>
                          Trip #{trip.trip_id || trip.tripId || trip.driver_pay_id}
                        </Typography>
                      </Grid>

                      <Grid item xs={6} sm={2}>
                        <Typography variant="caption" color="text.secondary">
                          Start Date
                        </Typography>
                        <Typography variant="body2">
                          {formatDate(
                            trip.trip_start_date || trip.start_date
                          )}
                        </Typography>
                      </Grid>

                      <Grid item xs={6} sm={2}>
                        <Typography variant="caption" color="text.secondary">
                          End Date
                        </Typography>
                        <Typography variant="body2">
                          {formatDate(
                            trip.trip_end_date || trip.end_date
                          )}
                        </Typography>
                      </Grid>

                      <Grid item xs={6} sm={2}>
                        <Typography variant="caption" color="text.secondary">
                          Mileage
                        </Typography>
                        <Typography variant="body2">
                          {formatValue(
                            trip.driver_mileage ?? trip.total_mileage
                          )}
                        </Typography>
                      </Grid>

                      <Grid item xs={6} sm={3}>
                        <Typography variant="caption" color="text.secondary">
                          Driver Income
                        </Typography>
                        <Typography fontWeight={700} color="success.main">
                          {formatMoney(trip.driver_income)}
                        </Typography>
                      </Grid>
                    </Grid>
                  </AccordionSummary>

                  <AccordionDetails>
                    {/* Trip information */}
                    <Typography variant="subtitle1" fontWeight={600} mb={2}>
                      Trip Information
                    </Typography>

                    <Grid container spacing={2} mb={3}>
                      <Grid item xs={12} sm={4}>
                        <Typography variant="caption" color="text.secondary">
                          Trip ID
                        </Typography>
                        <Typography>
                          {formatValue(trip.trip_id || trip.tripId)}
                        </Typography>
                      </Grid>

                      <Grid item xs={12} sm={4}>
                        <Typography variant="caption" color="text.secondary">
                          Truck
                        </Typography>
                        <Typography>
                        {trip.truck_number || '-'}
                        </Typography>
                      </Grid>

                      <Grid item xs={12} sm={4}>
                        <Typography variant="caption" color="text.secondary">
                          Trailer(s)
                        </Typography>
                        <Typography>
                        {trip.trailer_numbers || '-'}
                        </Typography>
                      </Grid>

                      <Grid item xs={12} sm={4}>
                        <Typography variant="caption" color="text.secondary">
                          Trip Type
                        </Typography>
                        <Typography>
                          {formatValue(trip.driver_type)}
                        </Typography>
                      </Grid>

                      <Grid item xs={12} sm={4}>
                        <Typography variant="caption" color="text.secondary">
                          Total Trip Mileage
                        </Typography>
                        <Typography>
                          {formatValue(trip.total_mileage)}
                        </Typography>
                      </Grid>

                      <Grid item xs={12} sm={4}>
                        <Typography variant="caption" color="text.secondary">
                          Average
                        </Typography>
                        <Typography>
                          {formatValue(trip.average)}
                        </Typography>
                      </Grid>
                    </Grid>

                    <Divider sx={{ my: 2 }} />

                    {/* Pickup and delivery locations */}
                    <Typography variant="subtitle1" fontWeight={600} mb={2}>
                      Pickup & Delivery Locations
                    </Typography>

                    {trip.locations?.length ? (
                      <Table size="small">
                        <TableHead>
                          <TableRow>
                            <TableCell>Stop</TableCell>
                            <TableCell>Pickup Location</TableCell>
                            <TableCell>Delivery Location</TableCell>
                            <TableCell>Mileage</TableCell>
                           
                          </TableRow>
                        </TableHead>

                        <TableBody>
                          {trip.locations.map((location: any, index: number) => (
                            <TableRow key={location.id}>
                              <TableCell>{index + 1}</TableCell>

                              <TableCell>
                                {formatValue(location.pickup_location)}
                              </TableCell>

                              <TableCell>
                                {formatValue(location.delivery_location)}
                              </TableCell>

                              <TableCell>
                                {formatValue(location.mileage)}
                              </TableCell>

                             
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    ) : (
                      <Typography color="text.secondary">
                        No pickup/delivery locations found for this trip.
                      </Typography>
                    )}

                    <Divider sx={{ my: 2 }} />

                    {/* Payment information */}
                    <Typography variant="subtitle1" fontWeight={600} mb={2}>
                      Payment Details
                    </Typography>

                    <Grid container spacing={2}>
                      <Grid item xs={12} sm={3}>
                        <Typography variant="caption" color="text.secondary">
                          Driver Income
                        </Typography>
                        <Typography fontWeight={600}>
                          {formatMoney(trip.driver_income)}
                        </Typography>
                      </Grid>

                      <Grid item xs={12} sm={3}>
                        <Typography variant="caption" color="text.secondary">
                          Deductions
                        </Typography>
                        <Typography>
                          {formatMoney(trip.total_deductible)}
                        </Typography>
                      </Grid>

                      <Grid item xs={12} sm={3}>
                        <Typography variant="caption" color="text.secondary">
                          Adjustment
                        </Typography>
                        <Typography>
                          {formatMoney(trip.adjustment)}
                        </Typography>
                      </Grid>

                      <Grid item xs={12} sm={3}>
                        <Typography variant="caption" color="text.secondary">
                          Payment Status
                        </Typography>
                        <Chip
                          size="small"
                          label={trip.payment_status || 'Unpaid'}
                          color={
                            trip.payment_status === 'paid'
                              ? 'success'
                              : 'warning'
                          }
                        />
                      </Grid>

                      <Grid item xs={12} sm={3}>
                        <Typography variant="caption" color="text.secondary">
                          Other Pay
                        </Typography>
                        <Typography>
                          {formatMoney(trip.other_pay)}
                        </Typography>
                      </Grid>

                      <Grid item xs={12} sm={3}>
                        <Typography variant="caption" color="text.secondary">
                          Layover
                        </Typography>
                        <Typography>
                          {formatMoney(trip.layover)}
                        </Typography>
                      </Grid>

                      <Grid item xs={12} sm={3}>
                        <Typography variant="caption" color="text.secondary">
                          Driver Additional Pay
                        </Typography>
                        <Typography>
                          {formatMoney(trip.driver_addv)}
                        </Typography>
                      </Grid>

                      <Grid item xs={12} sm={12}>
                        <Typography variant="caption" color="text.secondary">
                          Note
                        </Typography>
                        <Typography>
                          {formatValue(trip.note)}
                        </Typography>
                      </Grid>
                    </Grid>
                  </AccordionDetails>
                </Accordion>
              ))}
            </Stack>
          ) : (
            <Typography color="text.secondary">
              No trip records found for this driver.
            </Typography>
          )}

          {pagination?.totalPages > 1 && (
            <Box display="flex" justifyContent="center" mt={3}>
              <Pagination
                count={pagination.totalPages}
                page={page}
                onChange={(_, value) => setPage(value)}
                color="primary"
              />
            </Box>
          )}
        </CardContent>
      </Card>
    </Box>
  );
}