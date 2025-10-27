import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import {
  ComposedChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
  ReferenceLine,
  Area,
} from "recharts";
import { format, subMinutes, differenceInMinutes } from "date-fns";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";

interface EnhancedHeartRateChartProps {
  patientId: string;
}

const EnhancedHeartRateChart = ({ patientId }: EnhancedHeartRateChartProps) => {
  const [selectedPoint, setSelectedPoint] = useState<any>(null);

  // Fetch heart rate data
  const { data: hrData } = useQuery({
    queryKey: ["heartrate-detailed", patientId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("heartrate_data")
        .select("*")
        .eq("patient_id", patientId)
        .order("recorded_at", { ascending: true })
        .limit(1000);
      
      if (error) throw error;
      return data;
    },
  });

  // Fetch BP data
  const { data: bpData } = useQuery({
    queryKey: ["bp-data", patientId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("bp_data")
        .select("*")
        .eq("patient_id", patientId)
        .order("recorded_at", { ascending: true });
      
      if (error) throw error;
      return data;
    },
  });

  // Fetch symptom logs
  const { data: symptoms } = useQuery({
    queryKey: ["symptoms-for-chart", patientId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("symptom_logs")
        .select("*")
        .eq("patient_id", patientId)
        .order("timestamp", { ascending: true });
      
      if (error) throw error;
      return data;
    },
  });

  // Process data for analysis
  const processedData = hrData?.map((hr, index) => {
    const hrTime = new Date(hr.recorded_at);
    
    // 30-second moving window average
    const windowStart = subMinutes(hrTime, 0.5);
    const windowEnd = hrTime;
    const windowData = hrData.filter((d) => {
      const t = new Date(d.recorded_at);
      return t >= windowStart && t <= windowEnd;
    });
    const windowAvg = windowData.reduce((sum, d) => sum + d.heart_rate, 0) / windowData.length;

    // 10-second baseline (prior to window)
    const baselineStart = subMinutes(windowStart, 10 / 60);
    const baselineEnd = windowStart;
    const baselineData = hrData.filter((d) => {
      const t = new Date(d.recorded_at);
      return t >= baselineStart && t <= baselineEnd;
    });
    const baselineAvg = baselineData.length > 0
      ? baselineData.reduce((sum, d) => sum + d.heart_rate, 0) / baselineData.length
      : windowAvg;

    // Check HR increase
    const hrIncrease = windowAvg - baselineAvg;
    
    // Check for BP change (find closest BP reading)
    const closestBP = bpData?.reduce((closest, bp) => {
      const bpTime = new Date(bp.recorded_at);
      const diff = Math.abs(differenceInMinutes(hrTime, bpTime));
      const closestDiff = closest ? Math.abs(differenceInMinutes(hrTime, new Date(closest.recorded_at))) : Infinity;
      return diff < closestDiff ? bp : closest;
    }, null as any);

    // Check for symptoms within 1 hour
    const symptomInHour = symptoms?.some((s) => {
      const sTime = new Date(s.timestamp);
      const diff = Math.abs(differenceInMinutes(hrTime, sTime));
      return diff <= 60;
    });

    // Determine alert level
    let alertLevel: 'none' | 'yellow' | 'orange' | 'red' = 'none';
    if (symptomInHour) {
      alertLevel = 'red';
    } else if (closestBP && Math.abs(closestBP.systolic - (hrData[0]?.heart_rate || 120)) > 10) {
      alertLevel = 'orange';
    } else if (hrIncrease > 30) {
      alertLevel = 'yellow';
    }

    return {
      time: format(hrTime, "HH:mm:ss"),
      fullTime: hr.recorded_at,
      hr: hr.heart_rate,
      windowAvg,
      baselineAvg,
      hrIncrease,
      alertLevel,
      bp: closestBP ? `${closestBP.systolic}/${closestBP.diastolic}` : null,
      symptoms: symptomInHour,
    };
  }) || [];

  const CustomDot = (props: any) => {
    const { cx, cy, payload } = props;
    
    const colors = {
      none: 'hsl(var(--primary))',
      yellow: '#FFB800',
      orange: '#FF8C00',
      red: '#EF4444',
    };

    return (
      <circle
        cx={cx}
        cy={cy}
        r={payload.alertLevel !== 'none' ? 6 : 3}
        fill={colors[payload.alertLevel as keyof typeof colors]}
        stroke="white"
        strokeWidth={2}
        style={{ cursor: 'pointer' }}
        onClick={() => setSelectedPoint(payload)}
      />
    );
  };

  const CustomTooltip = ({ active, payload }: any) => {
    if (!active || !payload || !payload[0]) return null;

    const data = payload[0].payload;
    return (
      <div className="bg-card p-3 border border-border rounded-lg shadow-lg">
        <p className="font-semibold">{data.time}</p>
        <p className="text-sm">HR: <span className="font-bold">{data.hr}</span> bpm</p>
        <p className="text-sm">Window Avg: {data.windowAvg.toFixed(1)} bpm</p>
        <p className="text-sm">Baseline: {data.baselineAvg.toFixed(1)} bpm</p>
        <p className="text-sm">Change: {data.hrIncrease > 0 ? '+' : ''}{data.hrIncrease.toFixed(1)} bpm</p>
        {data.bp && <p className="text-sm">BP: {data.bp}</p>}
        {data.alertLevel !== 'none' && (
          <Badge variant={data.alertLevel === 'red' ? 'destructive' : 'default'} className="mt-2">
            {data.alertLevel === 'red' && 'Symptoms Reported'}
            {data.alertLevel === 'orange' && 'BP Change'}
            {data.alertLevel === 'yellow' && 'HR Spike'}
          </Badge>
        )}
      </div>
    );
  };

  return (
    <>
      <Card>
        <CardHeader>
          <CardTitle>Enhanced Heart Rate & BP Analysis</CardTitle>
          <CardDescription>
            Interactive monitoring with automated POTS episode detection
          </CardDescription>
          <div className="flex gap-2 mt-4">
            <Badge variant="outline" className="bg-[#FFB800]/10">
              <div className="w-3 h-3 bg-[#FFB800] rounded-full mr-2" />
              HR Spike &gt;30 bpm
            </Badge>
            <Badge variant="outline" className="bg-[#FF8C00]/10">
              <div className="w-3 h-3 bg-[#FF8C00] rounded-full mr-2" />
              BP Change
            </Badge>
            <Badge variant="outline" className="bg-destructive/10">
              <div className="w-3 h-3 bg-destructive rounded-full mr-2" />
              Patient Symptoms
            </Badge>
          </div>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={500}>
            <ComposedChart data={processedData}>
              <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
              <XAxis
                dataKey="time"
                tick={{ fill: "hsl(var(--muted-foreground))" }}
              />
              <YAxis
                tick={{ fill: "hsl(var(--muted-foreground))" }}
                label={{ value: "Heart Rate (bpm)", angle: -90, position: "insideLeft" }}
              />
              <Tooltip content={<CustomTooltip />} />
              <Legend />
              
              {/* Highlighted regions */}
              {processedData.map((point, i) => {
                if (point.alertLevel === 'yellow') {
                  return (
                    <ReferenceLine
                      key={`yellow-${i}`}
                      x={point.time}
                      stroke="#FFB800"
                      strokeWidth={20}
                      strokeOpacity={0.2}
                    />
                  );
                }
                return null;
              })}
              
              <Line
                type="monotone"
                dataKey="hr"
                stroke="hsl(var(--primary))"
                name="Heart Rate"
                strokeWidth={2}
                dot={<CustomDot />}
                activeDot={{ r: 8 }}
              />
              
              <Line
                type="monotone"
                dataKey="baselineAvg"
                stroke="hsl(var(--muted-foreground))"
                strokeDasharray="5 5"
                name="Baseline (10s prior)"
                strokeWidth={1}
                dot={false}
              />
            </ComposedChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      {/* Patient Feedback Dialog */}
      <Dialog open={!!selectedPoint} onOpenChange={() => setSelectedPoint(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Episode Details - {selectedPoint?.time}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-muted-foreground">Heart Rate</p>
                <p className="text-2xl font-bold">{selectedPoint?.hr} bpm</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Change from Baseline</p>
                <p className="text-2xl font-bold">
                  {selectedPoint?.hrIncrease > 0 ? '+' : ''}
                  {selectedPoint?.hrIncrease?.toFixed(1)} bpm
                </p>
              </div>
            </div>

            {selectedPoint?.bp && (
              <div>
                <p className="text-sm text-muted-foreground">Blood Pressure</p>
                <p className="text-lg font-semibold">{selectedPoint.bp}</p>
              </div>
            )}

            {selectedPoint?.symptoms && (
              <div className="bg-destructive/10 border border-destructive/20 rounded-lg p-4">
                <p className="font-semibold text-destructive">⚠️ Patient Reported Symptoms</p>
                <p className="text-sm mt-2">
                  The patient logged symptoms within 1 hour of this reading. This may indicate
                  a POTS episode requiring attention.
                </p>
              </div>
            )}

            {selectedPoint?.alertLevel === 'yellow' && (
              <div className="bg-[#FFB800]/10 border border-[#FFB800]/20 rounded-lg p-4">
                <p className="font-semibold" style={{ color: '#FFB800' }}>
                  Significant Heart Rate Increase Detected
                </p>
                <p className="text-sm mt-2">
                  30-second moving average shows {'>'}30 bpm increase from baseline.
                </p>
              </div>
            )}

            {selectedPoint?.alertLevel === 'orange' && (
              <div className="bg-[#FF8C00]/10 border border-[#FF8C00]/20 rounded-lg p-4">
                <p className="font-semibold" style={{ color: '#FF8C00' }}>
                  Blood Pressure Change Detected
                </p>
                <p className="text-sm mt-2">
                  Notable change in blood pressure from patient's baseline.
                </p>
              </div>
            )}
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
};

export default EnhancedHeartRateChart;
