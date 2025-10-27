import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from "recharts";
import { format } from "date-fns";

interface HeartRateChartProps {
  patientId: string;
}

const HeartRateChart = ({ patientId }: HeartRateChartProps) => {
  const { data: heartRateData, isLoading } = useQuery({
    queryKey: ["heartrate", patientId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("heartrate_hourly_summary")
        .select("*")
        .eq("patient_id", patientId)
        .order("hour_timestamp", { ascending: true })
        .limit(168); // Last week of hourly data
      
      if (error) throw error;
      return data;
    },
  });

  const { data: recentHR } = useQuery({
    queryKey: ["heartrate-recent", patientId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("heartrate_data")
        .select("*")
        .eq("patient_id", patientId)
        .order("recorded_at", { ascending: false })
        .limit(100);
      
      if (error) throw error;
      return data;
    },
  });

  const chartData = heartRateData?.map((item) => ({
    time: format(new Date(item.hour_timestamp), "MMM dd HH:mm"),
    avg: item.avg_hr,
    min: item.min_hr,
    max: item.max_hr,
  })) || [];

  const avgHeartRate = recentHR?.length
    ? Math.round(recentHR.reduce((sum, item) => sum + item.heart_rate, 0) / recentHR.length)
    : 0;

  return (
    <Card>
      <CardHeader>
        <CardTitle>Heart Rate Trends</CardTitle>
        <CardDescription>Hourly aggregated heart rate data (last 7 days)</CardDescription>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="h-80 flex items-center justify-center text-muted-foreground">
            Loading heart rate data...
          </div>
        ) : chartData.length > 0 ? (
          <>
            <div className="mb-6 grid grid-cols-3 gap-4">
              <div className="text-center">
                <p className="text-sm text-muted-foreground">Average HR</p>
                <p className="text-3xl font-bold text-primary">{avgHeartRate}</p>
                <p className="text-xs text-muted-foreground">bpm</p>
              </div>
              <div className="text-center">
                <p className="text-sm text-muted-foreground">Min HR</p>
                <p className="text-3xl font-bold text-accent">
                  {Math.min(...(recentHR?.map(r => r.heart_rate) || [0]))}
                </p>
                <p className="text-xs text-muted-foreground">bpm</p>
              </div>
              <div className="text-center">
                <p className="text-sm text-muted-foreground">Max HR</p>
                <p className="text-3xl font-bold text-destructive">
                  {Math.max(...(recentHR?.map(r => r.heart_rate) || [0]))}
                </p>
                <p className="text-xs text-muted-foreground">bpm</p>
              </div>
            </div>
            <ResponsiveContainer width="100%" height={400}>
              <LineChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
                <XAxis 
                  dataKey="time" 
                  className="text-xs"
                  tick={{ fill: "hsl(var(--muted-foreground))" }}
                />
                <YAxis 
                  className="text-xs"
                  tick={{ fill: "hsl(var(--muted-foreground))" }}
                  label={{ value: "Heart Rate (bpm)", angle: -90, position: "insideLeft" }}
                />
                <Tooltip 
                  contentStyle={{ 
                    backgroundColor: "hsl(var(--card))",
                    border: "1px solid hsl(var(--border))",
                    borderRadius: "var(--radius)"
                  }}
                />
                <Legend />
                <Line 
                  type="monotone" 
                  dataKey="avg" 
                  stroke="hsl(var(--primary))" 
                  name="Average HR"
                  strokeWidth={2}
                />
                <Line 
                  type="monotone" 
                  dataKey="min" 
                  stroke="hsl(var(--accent))" 
                  name="Min HR"
                  strokeWidth={1}
                  strokeDasharray="5 5"
                />
                <Line 
                  type="monotone" 
                  dataKey="max" 
                  stroke="hsl(var(--destructive))" 
                  name="Max HR"
                  strokeWidth={1}
                  strokeDasharray="5 5"
                />
              </LineChart>
            </ResponsiveContainer>
          </>
        ) : (
          <div className="h-80 flex items-center justify-center text-muted-foreground">
            No heart rate data available
          </div>
        )}
      </CardContent>
    </Card>
  );
};

export default HeartRateChart;
