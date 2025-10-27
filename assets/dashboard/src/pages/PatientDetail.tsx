import { useParams, useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ArrowLeft, Activity, Heart, Smartphone, FileText, ClipboardList } from "lucide-react";
import EnhancedHeartRateChart from "@/components/EnhancedHeartRateChart";
import StandUpTests from "@/components/StandUpTests";
import SymptomLogs from "@/components/SymptomLogs";
import DeviceInfo from "@/components/DeviceInfo";
import VossQuestionnaires from "@/components/VossQuestionnaires";

const PatientDetail = () => {
  const { patientId } = useParams();
  const navigate = useNavigate();

  const { data: patient, isLoading } = useQuery({
    queryKey: ["patient", patientId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("patients")
        .select("*")
        .eq("id", patientId)
        .single();
      
      if (error) throw error;
      return data;
    },
  });

  if (isLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-muted-foreground">Loading patient data...</div>
      </div>
    );
  }

  if (!patient) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-center space-y-4">
          <p className="text-muted-foreground">Patient not found</p>
          <Button onClick={() => navigate("/")}>Back to Dashboard</Button>
        </div>
      </div>
    );
  }

  const age = new Date().getFullYear() - new Date(patient.date_of_birth).getFullYear();

  return (
    <div className="bg-background">
      <div className="container mx-auto py-8 px-4 space-y-6">
        <Button variant="ghost" onClick={() => navigate("/dashboard")} className="mb-4">
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back to Dashboard
        </Button>

        <Card>
          <CardHeader>
            <CardTitle className="text-3xl">
              {patient.first_name} {patient.last_name}
            </CardTitle>
            <CardDescription>Patient ID: {patient.id}</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div>
                <p className="text-sm text-muted-foreground">Age</p>
                <p className="text-lg font-semibold">{age} years</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Sex</p>
                <p className="text-lg font-semibold">{patient.sex_assigned_at_birth}</p>
              </div>
              {patient.height_cm && (
                <div>
                  <p className="text-sm text-muted-foreground">Height</p>
                  <p className="text-lg font-semibold">{patient.height_cm} cm</p>
                </div>
              )}
              {patient.weight_kg && (
                <div>
                  <p className="text-sm text-muted-foreground">Weight</p>
                  <p className="text-lg font-semibold">{patient.weight_kg} kg</p>
                </div>
              )}
            </div>
            {patient.pots_diagnosis_date && (
              <div className="mt-4 pt-4 border-t">
                <p className="text-sm text-muted-foreground">POTS Diagnosis Date</p>
                <p className="text-lg font-semibold">
                  {new Date(patient.pots_diagnosis_date).toLocaleDateString()}
                </p>
              </div>
            )}
            {patient.reason_for_using_app && (
              <div className="mt-4">
                <p className="text-sm text-muted-foreground">Reason for Using App</p>
                <p className="text-base">{patient.reason_for_using_app}</p>
              </div>
            )}
          </CardContent>
        </Card>

        <Tabs defaultValue="heartrate" className="space-y-4">
          <TabsList className="grid w-full grid-cols-5">
            <TabsTrigger value="heartrate" className="flex items-center gap-2">
              <Heart className="h-4 w-4" />
              Heart Rate
            </TabsTrigger>
            <TabsTrigger value="tests" className="flex items-center gap-2">
              <Activity className="h-4 w-4" />
              Stand-Up Tests
            </TabsTrigger>
            <TabsTrigger value="symptoms" className="flex items-center gap-2">
              <ClipboardList className="h-4 w-4" />
              Symptoms
            </TabsTrigger>
            <TabsTrigger value="devices" className="flex items-center gap-2">
              <Smartphone className="h-4 w-4" />
              Devices
            </TabsTrigger>
            <TabsTrigger value="questionnaires" className="flex items-center gap-2">
              <FileText className="h-4 w-4" />
              VOSS
            </TabsTrigger>
          </TabsList>

          <TabsContent value="heartrate">
            <EnhancedHeartRateChart patientId={patientId!} />
          </TabsContent>

          <TabsContent value="tests">
            <StandUpTests patientId={patientId!} />
          </TabsContent>

          <TabsContent value="symptoms">
            <SymptomLogs patientId={patientId!} />
          </TabsContent>

          <TabsContent value="devices">
            <DeviceInfo patientId={patientId!} />
          </TabsContent>

          <TabsContent value="questionnaires">
            <VossQuestionnaires patientId={patientId!} />
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
};

export default PatientDetail;
