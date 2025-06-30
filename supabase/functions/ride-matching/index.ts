import { createClient } from 'npm:@supabase/supabase-js@2.39.7'
import { corsHeaders } from '../_shared/cors.ts'

interface RideMatchRequest {
  rideId: string
  pickupLat: number
  pickupLng: number
  maxDistance?: number
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { rideId, pickupLat, pickupLng, maxDistance = 5 }: RideMatchRequest = await req.json()

    if (!rideId || !pickupLat || !pickupLng) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: rideId, pickupLat, pickupLng' }),
        {
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
          status: 400,
        }
      )
    }

    // Find available drivers within the specified distance
    const { data: availableDrivers, error } = await supabaseClient
      .from('driver_locations')
      .select(`
        driver_id,
        latitude,
        longitude,
        profiles!driver_locations_driver_id_fkey (
          id,
          full_name,
          phone
        )
      `)
      .eq('is_available', true)
      .gte('last_updated', new Date(Date.now() - 5 * 60 * 1000).toISOString()) // Active in last 5 minutes

    if (error) {
      throw error
    }

    // Calculate distances and filter by maxDistance
    const nearbyDrivers = availableDrivers
      ?.filter(driver => {
        const distance = calculateDistance(
          pickupLat,
          pickupLng,
          parseFloat(driver.latitude),
          parseFloat(driver.longitude)
        )
        return distance <= maxDistance
      })
      .map(driver => ({
        ...driver,
        distance: calculateDistance(
          pickupLat,
          pickupLng,
          parseFloat(driver.latitude),
          parseFloat(driver.longitude)
        )
      }))
      .sort((a, b) => a.distance - b.distance) || []

    // Send ride requests to nearby drivers
    const rideRequests = nearbyDrivers.slice(0, 5).map(driver => ({
      ride_id: rideId,
      driver_id: driver.driver_id,
      status: 'sent',
    }))

    if (rideRequests.length > 0) {
      const { error: insertError } = await supabaseClient
        .from('ride_requests')
        .insert(rideRequests)

      if (insertError) {
        throw insertError
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        driversFound: nearbyDrivers.length,
        requestsSent: rideRequests.length,
        drivers: nearbyDrivers.slice(0, 5)
      }),
      {
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
        status: 200,
      }
    )

  } catch (error) {
    console.error('Error in ride-matching function:', error)
    
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        message: error.message 
      }),
      {
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
        status: 500,
      }
    )
  }
})

// Haversine formula to calculate distance between two points
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371 // Earth's radius in kilometers
  const dLat = (lat2 - lat1) * Math.PI / 180
  const dLon = (lon2 - lon1) * Math.PI / 180
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLon/2) * Math.sin(dLon/2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
  return R * c
}