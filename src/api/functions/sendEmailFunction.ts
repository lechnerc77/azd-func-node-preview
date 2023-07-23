import { app } from "@azure/functions";
import { EmailClient } from "@azure/communication-email";
const connectionString = process.env["COMSRVC-CONNECTION-STRING"];
const emailDomain = process.env["EMAIL_SERVICE_DOMAIN"];
const emailClient = new EmailClient(connectionString);

class emailInfo {
	firstName: string;
	lastName: string;
	email: string;
}

app.http("sendEmail", {
	methods: ["POST"],
	authLevel: "function",
	handler: async (request, context) => {
		context.log(
			`HTTP triggered function processed request for url "${request.url}"`,
		);

		let returnStatus = 201;
		let returnBody = "Email sent successfully";
		const requestBody = await request.json();

		const emailFromRequest = Object.assign(new emailInfo(), requestBody);

		const response = await sendEmail(
			emailFromRequest.firstName,
			emailFromRequest.lastName,
			emailFromRequest.email,
			context,
		);

		if (response.status === "Failed" || response.status === "Cancelled") {
			returnStatus = 500;
			returnBody = "Email failed to send";
		}
		return {
			status: returnStatus,
			body: returnBody,
		};
	},
});

async function sendEmail(firstName, lastName, email, context) {
	try {
		const message = {
			senderAddress:
				`<donotreply@${emailDomain}>`,
			content: {
				subject: "Welcome to Azure Communication Services Email",
				plainText: `Hello ${firstName} ${lastName}. \n This email message is sent from Azure Communication Services Email.`,
			},
			recipients: {
				to: [
					{
						address: email,
						displayName: `${firstName} ${lastName}`,
					},
				],
			},
		};

		const poller = await emailClient.beginSend(message);

		const response = await poller.pollUntilDone();

		if (response.status === "Succeeded") {
			context.log("Email sent successfully");
		} else {
			context.log("Email failed to send");
		}

		return response;
	} catch (e) {
		context.log(e);
	}
}
